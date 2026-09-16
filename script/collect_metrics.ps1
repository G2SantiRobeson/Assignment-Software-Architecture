param(
    [string]$ProjectName = 'book-reviews-a4',
    [Parameter(Mandatory=$true)][string]$OutputDir,
    [Parameter(Mandatory=$true)][string]$StopFile,
    [int]$IntervalSeconds = 5,
    [string]$KubernetesContext = ''
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $OutputDir | Out-Null
while (!(Test-Path -LiteralPath $StopFile)) {
    $timestamp = [DateTime]::UtcNow.ToString('o')
    if ($KubernetesContext) {
        $pods = (& kubectl --context $KubernetesContext -n book-reviews get pods -o json | ConvertFrom-Json).items | Where-Object { $_.status.phase -eq 'Running' }
        $top = & kubectl --context $KubernetesContext -n book-reviews top pods --containers --no-headers 2>&1
        @{timestamp=$timestamp;usage=@($top | ForEach-Object { "$_" })} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'kubernetes-usage.jsonl')
        foreach ($pod in $pods) {
            foreach ($container in $pod.spec.containers) {
                $threads = & kubectl --context $KubernetesContext -n book-reviews exec $pod.metadata.name -c $container.name -- sh -c 'for s in /proc/[0-9]*/status; do awk ''/^Name:|^Pid:|^Threads:/ {print}'' "$s" 2>/dev/null; done' 2>&1
                @{timestamp=$timestamp;pod=$pod.metadata.name;container=$container.name;processes=@($threads | ForEach-Object { "$_" })} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'threads.jsonl')
            }
        }
    } else {
        $ids = @(& docker ps -q --filter "label=com.docker.compose.project=$ProjectName")
        if ($ids.Count -gt 0) {
            $stats = & docker stats --no-stream --format '{{json .}}' @ids
            foreach ($line in $stats) {
                @{timestamp=$timestamp;stats=($line | ConvertFrom-Json)} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'containers.jsonl')
            }
            foreach ($id in $ids) {
                # NLWP is the real per-process thread count; Docker PIDs also counts threads.
                $processes = & docker top $id -eo pid,nlwp,comm
                @{timestamp=$timestamp;container=$id;processes=@($processes)} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'threads.jsonl')
            }
        }
    }
    Start-Sleep -Seconds $IntervalSeconds
}
