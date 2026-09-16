param(
    [ValidateSet('single','proxy','full','scaled')][string]$Deployment = 'scaled',
    [string]$ProjectName = 'book-reviews-a4',
    [string]$BaseUrl = 'https://app.localhost',
    [ValidateRange(1,1000000)][int[]]$Counts = @(1,10,100,1000,5000),
    [ValidateSet('static','aggregation','search','book')][string[]]$Endpoints = @('static','aggregation','search','book'),
    [ValidateRange(1,86400)][int]$DurationSeconds = 300,
    [string]$KubernetesContext = ''
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$root = (Get-Location).Path
$compose = @('compose','--env-file','.env','-p',$ProjectName,'-f',"compose/compose.$Deployment.yaml")
if ($KubernetesContext) {
    $deploymentState = & kubectl --context $KubernetesContext -n book-reviews get deployment book-reviews-web -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $deploymentState.spec.replicas -ne 3 -or $deploymentState.status.readyReplicas -ne 3) {
        throw 'The Kubernetes load-test target must have 3 ready Rails replicas.'
    }
    $fixtureOutput = & kubectl --context $KubernetesContext -n book-reviews exec deployment/book-reviews-web -c rails -- bin/rails assignment4:load_data
} else {
    $expectedReplicas = if ($Deployment -eq 'scaled') { 3 } else { 1 }
    $runningReplicas = @(& docker @compose ps --status running -q web)
    if ($LASTEXITCODE -ne 0 -or $runningReplicas.Count -ne $expectedReplicas) {
        throw "Deployment $Deployment requires $expectedReplicas running Rails replicas; found $($runningReplicas.Count). Start the matching deployment before measuring."
    }
    $fixtureOutput = & docker @compose exec -T web bin/rails assignment4:load_data
}
if ($LASTEXITCODE -ne 0) { throw 'Load fixture preparation failed' }
$fixture = ($fixtureOutput | Where-Object { $_ -match '^\{"book_path"' } | Select-Object -Last 1) | ConvertFrom-Json
if (!$fixture) { throw 'Load fixtures did not return endpoint paths' }
$paths = @{static=$fixture.image_path;aggregation=$fixture.aggregation_path;search=$fixture.search_path;book=$fixture.book_path}
$appHost = ([Uri]$BaseUrl).Host
$searchBackend = if ($Deployment -in @('full','scaled') -or $KubernetesContext) { 'opensearch' } else { 'postgresql' }
$run = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($count in $Counts) {
    foreach ($endpoint in $Endpoints) {
        $relative = "results/$run-$Deployment-$endpoint-$count"
        $outputDir = Join-Path $root $relative
        New-Item -ItemType Directory -Force $outputDir | Out-Null
        $stop = Join-Path $outputDir 'stop'
        @{deployment=$Deployment;requests=$count;durationSeconds=$DurationSeconds;endpoint=$endpoint;url="$BaseUrl$($paths[$endpoint])";startedUtc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $outputDir 'run.json')
        $job = Start-Job -FilePath (Join-Path $PSScriptRoot 'collect_metrics.ps1') -ArgumentList $ProjectName,$outputDir,$stop,5,$KubernetesContext
        try {
            # The local certificate is self-signed. Only this test client skips trust;
            # verify_http.rb separately verifies TLS with the generated CA certificate.
            & docker run --rm --user '0:0' --add-host "${appHost}:host-gateway" --mount "type=bind,source=$root/load,target=/scripts,readonly" --mount "type=bind,source=$outputDir,target=/results" -e "BASE_URL=$BaseUrl" -e "TARGET_PATH=$($paths[$endpoint])" -e "REQUESTS=$count" -e "DURATION_SECONDS=$DurationSeconds" -e "ENDPOINT=$endpoint" -e "DEPLOYMENT=$Deployment" -e "EXPECT_SEARCH=$searchBackend" -e INSECURE_TLS=true grafana/k6:1.6.1 run --quiet --out json=/results/samples.json /scripts/edge.js
            if ($LASTEXITCODE -ne 0) { throw "k6 failed: $endpoint / $count; see $relative" }
        } finally {
            New-Item -ItemType File -Force $stop | Out-Null
            $job | Wait-Job -Timeout 30 | Out-Null
            $job | Receive-Job | Out-File (Join-Path $outputDir 'collector.log')
            $job | Stop-Job
            $job | Remove-Job
            if (!$KubernetesContext -and $Deployment -ne 'single') {
                & docker @compose logs --no-color traefik | Out-File (Join-Path $outputDir 'traefik.jsonl')
            }
        }
        Write-Output "Captured $relative"
    }
}
