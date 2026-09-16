param(
    [ValidateSet('single','proxy','full','scaled')][string]$Deployment = 'scaled',
    [string]$ProjectName = 'book-reviews-a4',
    [string]$BaseUrl = 'https://app.localhost',
    [string]$KubernetesContext = '',
    [switch]$Failover,
    [int]$HttpPort = 0
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$root = (Get-Location).Path
$uri = [Uri]$BaseUrl
$run = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputDir = Join-Path $root "results/verification/$run-$Deployment"
New-Item -ItemType Directory -Force $outputDir | Out-Null
$replicas = if ($Deployment -eq 'scaled' -or $KubernetesContext) { 3 } else { 1 }
$edge = if ($uri.Scheme -eq 'https') { 'true' } else { 'false' }
$search = if ($Deployment -in @('full','scaled') -or $KubernetesContext) { 'opensearch' } else { 'postgresql' }
$compose = @('compose','--env-file','.env','-p',$ProjectName,'-f',"compose/compose.$Deployment.yaml")

if (!$KubernetesContext) {
    $webIds = @(& docker @compose ps -q web)
    if ($webIds.Count -ne $replicas) { throw "Expected $replicas running Rails containers, found $($webIds.Count)" }
    if ($edge -eq 'true') {
        foreach ($id in $webIds) {
            $bindings = (& docker inspect $id | ConvertFrom-Json)[0].HostConfig.PortBindings
            if ($bindings -and @($bindings.PSObject.Properties).Count -gt 0) { throw 'Rails is directly published to the host' }
        }
    }
} else {
    $pods = (& kubectl --context $KubernetesContext -n book-reviews get pods -l app.kubernetes.io/component=web -o json | ConvertFrom-Json).items
    if ($pods.Count -ne 3) { throw 'Expected 3 Rails pods' }
}

if ($edge -eq 'true') {
    if (!$HttpPort) {
        $configured = Get-Content .env | Where-Object { $_ -match '^HTTP_PORT=' } | Select-Object -Last 1
        $HttpPort = if ($KubernetesContext) { 8080 } elseif ($env:HTTP_PORT) { [int]$env:HTTP_PORT } elseif ($configured) { [int]($configured -split '=',2)[1] } else { 80 }
    }
    $redirect = & curl.exe -sS --resolve "$($uri.Host):${httpPort}:127.0.0.1" -o NUL -w '%{http_code}' "http://$($uri.Host):$httpPort/books"
    if ($redirect -notin @('301','302','307','308')) { throw "HTTP did not redirect to HTTPS: $redirect" }
}
$result = & docker run --rm --add-host "$($uri.Host):host-gateway" --mount "type=bind,source=$root,target=/workspace,readonly" -e "BASE_URL=$BaseUrl" -e TLS_CA=/workspace/tmp/edge/tls/tls.crt -e "EXPECT_EDGE=$edge" -e "EXPECT_SEARCH=$search" -e "EXPECT_REPLICAS=$replicas" --entrypoint bundle book-reviews:assignment4 exec ruby /workspace/script/verify_http.rb
$httpExit = $LASTEXITCODE
$result | Set-Content (Join-Path $outputDir 'http.log')
if ($httpExit -ne 0) { $result | Write-Output; throw 'HTTP verification failed' }
$summary = $result[-1] | ConvertFrom-Json
Write-Output "PASS: HTTPS/HTTP, uploads, sessions, assets, reports, search; instances: $($summary.instances | ConvertTo-Json -Compress)"
if ($KubernetesContext) {
    & kubectl --context $KubernetesContext -n book-reviews exec deployment/book-reviews-web -c rails -- bin/rails assignment4:verify_dependencies
} else {
    & docker @compose exec -T web bin/rails assignment4:verify_dependencies
}
if ($LASTEXITCODE -ne 0) { throw 'Dependency verification failed' }

if ($Failover) {
    if ($replicas -ne 3) { throw 'Failover verification requires 3 replicas' }
    $stopped = $null
    try {
        if ($KubernetesContext) {
            $removed = $pods[0].metadata.name
            & kubectl --context $KubernetesContext -n book-reviews delete pod $removed --wait=false
            if ($LASTEXITCODE -ne 0) { throw 'Pod deletion failed' }
        } else {
            $stopped = $webIds[0]
            & docker stop $stopped
            if ($LASTEXITCODE -ne 0) { throw 'Container stop failed' }
        }
        # Record the convergence period too; then require 30 successful reads.
        $samples = @()
        for ($i=0; $i -lt 40; $i++) {
            $headers = Join-Path $outputDir 'headers.tmp'
            $code = & curl.exe -sS --cacert tmp/edge/tls/tls.crt --resolve "$($uri.Host):$($uri.Port):127.0.0.1" -D $headers -o NUL -w '%{http_code}' "$BaseUrl$($summary.book_path)"
            $instanceHeader = [string](Get-Content $headers | Where-Object { $_ -match '^x-app-instance:' } | Select-Object -First 1)
            $samples += @{timestamp=[DateTime]::UtcNow.ToString('o');status=$code;instance=$instanceHeader;phase=$(if ($i -lt 10) {'convergence'} else {'steady'})}
            if ($i -ge 10 -and $code -ne '200') { throw "Failover steady request failed: $code" }
            Start-Sleep -Milliseconds 500
        }
        $samples | ConvertTo-Json | Set-Content (Join-Path $outputDir 'failover.json')
        $imageCode = & curl.exe -sS --cacert tmp/edge/tls/tls.crt --resolve "$($uri.Host):$($uri.Port):127.0.0.1" -o NUL -w '%{http_code}' "$BaseUrl$($summary.image_path)"
        if ($imageCode -ne '200') { throw 'Image unavailable after replica removal' }
        Write-Output 'PASS: 30/30 steady requests and existing upload survived replica removal'
    } finally {
        if ($stopped) { & docker start $stopped | Out-Null }
        if ($KubernetesContext) { & kubectl --context $KubernetesContext -n book-reviews rollout status deployment/book-reviews-web --timeout=180s }
    }
}
Write-Output "Evidence: $outputDir"
