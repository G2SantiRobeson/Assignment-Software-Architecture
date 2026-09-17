param(
    [string]$ProjectName = 'book-reviews-a4',
    [string]$BaseUrl = 'https://app.localhost',
    [string]$ResultsDir = '',
    [ValidateRange(1,86400)][int]$DurationSeconds = 300,
    [ValidateRange(1,1000000)][int[]]$Counts = @(1,10,100,1000,5000),
    [ValidateSet('static','aggregation','search','book')][string[]]$Endpoints = @('static','aggregation','search','book'),
    [string]$PauseK3dCluster = ''
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$root = (Get-Location).Path
if (!$ResultsDir) { $ResultsDir = 'results/matrix-' + (Get-Date -Format 'yyyyMMdd-HHmmss') }
$output = if ([IO.Path]::IsPathRooted($ResultsDir)) { [IO.Path]::GetFullPath($ResultsDir) } else { [IO.Path]::GetFullPath((Join-Path $root $ResultsDir)) }
if (!$output.StartsWith(($root + '\results\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'ResultsDir must be inside repository results/' }
New-Item -ItemType Directory -Force $output | Out-Null
# Keep only one benchmark orchestrator active in this repository.
$lock = [IO.File]::Open((Join-Path $root 'results/load-matrix.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
$clusterStopped = $false
$state = @{status='preparing';startedUtc=[DateTime]::UtcNow.ToString('o');pid=$PID;project=$ProjectName;baseUrl=$BaseUrl;durationSeconds=$DurationSeconds;counts=$Counts;endpoints=$Endpoints;totalCases=(2*$Counts.Count*$Endpoints.Count);deployment='';results=$output}
function Save-State { $state | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $output 'matrix.json') -Encoding UTF8 }
function Docker-Checked { param([string[]]$Arguments) & docker @Arguments; if ($LASTEXITCODE -ne 0) { throw "Docker command failed: $($Arguments -join ' ')" } }
try {
    Save-State
    Docker-Checked @('version','--format','{{json .}}') | Out-File (Join-Path $output 'docker-version.json') -Encoding UTF8
    Docker-Checked @('info','--format','{{json .NCPU}} {{json .MemTotal}}') | Out-File (Join-Path $output 'docker-resources.txt') -Encoding UTF8
    Docker-Checked @('image','inspect','book-reviews:assignment4','grafana/k6:1.6.1','--format','{{.Id}} {{json .RepoTags}}') | Out-File (Join-Path $output 'images.txt') -Encoding UTF8
    Get-FileHash load/edge.js,load/process_snapshot.sh,script/collect_metrics.ps1 -Algorithm SHA256 | Select-Object Path,Hash | ConvertTo-Json | Set-Content (Join-Path $output 'script-hashes.json')
    if ($PauseK3dCluster) {
        $k3d = Join-Path $root 'tmp/tools/k3d.exe'
        if (!(Test-Path $k3d)) { $k3d = 'k3d' }
        $cluster = @(& $k3d cluster list -o json | ConvertFrom-Json) | Where-Object { $_.name -eq $PauseK3dCluster }
        if ($LASTEXITCODE -ne 0 -or !$cluster) { throw 'Requested k3d cluster not found' }
        $runningNodes = @(& docker ps -q --filter "label=k3d.cluster=$PauseK3dCluster")
        if ($runningNodes.Count -gt 0) {
            & $k3d cluster stop $PauseK3dCluster
            if ($LASTEXITCODE -ne 0) { throw 'Could not stop comparison-interfering k3d cluster' }
            $clusterStopped = $true
        }
    }
    foreach ($deployment in @('full','scaled')) {
        $replicas = if ($deployment -eq 'scaled') { 3 } else { 1 }
        $state.deployment = $deployment
        $state.status = 'starting-deployment'
        Save-State
        $compose = @('compose','--env-file','.env','-p',$ProjectName,'-f',"compose/compose.$deployment.yaml")
        Docker-Checked ($compose + @('up','-d','--no-build','--scale',"web=$replicas",'--wait','--wait-timeout','240'))
        $state.status = 'measuring'
        Save-State
        & (Join-Path $PSScriptRoot 'load_test.ps1') -Deployment $deployment -ProjectName $ProjectName -BaseUrl $BaseUrl -Counts $Counts -Endpoints $Endpoints -DurationSeconds $DurationSeconds -ResultsDir $output
    }
    $completed = @(Get-ChildItem -LiteralPath $output -Directory | Where-Object { $_.Name -match '^(full|scaled)-(static|aggregation|search|book)-\d+$' } | Where-Object { Test-Path (Join-Path $_.FullName 'completed.json') })
    if ($completed.Count -ne $state.totalCases) { throw "Expected $($state.totalCases) completed cases; found $($completed.Count)" }
    $completed | ForEach-Object {
        $run = Get-Content (Join-Path $_.FullName 'run.json') -Raw | ConvertFrom-Json
        $summary = Get-Content (Join-Path $_.FullName 'summary.json') -Raw | ConvertFrom-Json
        $duration = $summary.metrics.http_req_duration.values
        [pscustomobject]@{deployment=$run.deployment;endpoint=$run.endpoint;requested=$run.requests;duration_seconds=$run.durationSeconds;observed=$summary.metrics.http_reqs.values.count;failed_rate=$summary.metrics.http_req_failed.values.rate;avg_ms=$duration.avg;median_ms=$duration.med;p95_ms=$duration.'p(95)';min_ms=$duration.min;max_ms=$duration.max;directory=$_.Name}
    } | Export-Csv (Join-Path $output 'comparison.csv') -NoTypeInformation -Encoding UTF8
    $state.status = 'completed'
    $state.completedCases = $completed.Count
    $state.completedUtc = [DateTime]::UtcNow.ToString('o')
} catch {
    $state.status = 'failed'
    $state.error = $_.Exception.Message
    throw
} finally {
    Save-State
    if ($clusterStopped) {
        & $k3d cluster start $PauseK3dCluster
        $state.clusterRestoreExitCode = $LASTEXITCODE
        Save-State
    }
    $lock.Dispose()
}
Write-Output "Completed matrix: $output"
