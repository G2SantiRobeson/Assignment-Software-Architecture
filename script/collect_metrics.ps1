param(
    [string]$ProjectName = 'book-reviews-a4',
    [Parameter(Mandatory=$true)][string]$OutputDir,
    [Parameter(Mandatory=$true)][string]$StopFile,
    [int]$IntervalSeconds = 5,
    [string]$KubernetesContext = ''
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $OutputDir | Out-Null
$prepared = @{}
$previous = @{}
if (!$KubernetesContext) {
    $clockInfo = @(& docker run --rm --entrypoint ruby book-reviews:assignment4 -retc -e 'puts Etc.sysconf(Etc::SC_CLK_TCK); puts Etc.sysconf(Etc::SC_PAGESIZE)')
    if ($LASTEXITCODE -ne 0 -or $clockInfo.Count -ne 2) { throw 'Could not read Linux clock tick/page sizes' }
    $clockTicks = [double]$clockInfo[0]
    $pageBytes = [long]$clockInfo[1]
    @{clock_ticks_per_second=$clockTicks;page_bytes=$pageBytes;cpu_percent_basis='100 percent = one logical CPU';process_memory='RSS; shared pages can appear in multiple processes';interval_seconds=$IntervalSeconds} | ConvertTo-Json | Set-Content (Join-Path $OutputDir 'metrics-metadata.json')
}
while ($true) {
    # Capture one final sample after k6 finishes, so the last interval is included.
    $finalSample = Test-Path -LiteralPath $StopFile
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
        if ($LASTEXITCODE -ne 0 -or $ids.Count -eq 0) { throw 'No measurement containers available' }
        if ($ids.Count -gt 0) {
            $stats = & docker stats --no-stream --format '{{json .}}' @ids
            if ($LASTEXITCODE -ne 0) { throw 'Docker stats collection failed' }
            foreach ($id in $ids) {
                if (!$prepared.ContainsKey($id)) {
                    & docker cp (Join-Path $PSScriptRoot '../load/process_snapshot.sh') "${id}:/tmp/edge-load-process-snapshot.sh"
                    if ($LASTEXITCODE -ne 0) { throw "Cannot install process sampler in $id" }
                    $info = (& docker inspect $id | ConvertFrom-Json)[0]
                    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect $id" }
                    $prepared[$id] = $info.Name.TrimStart('/')
                    @{id=$id;name=$prepared[$id];image=$info.Image;service=$info.Config.Labels.'com.docker.compose.service';memory_limit_bytes=$info.HostConfig.Memory;nano_cpus=$info.HostConfig.NanoCpus} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'container-identities.jsonl')
                }
                $snapshot = @(& docker exec $id sh /tmp/edge-load-process-snapshot.sh)
                if ($LASTEXITCODE -ne 0 -or $snapshot.Count -lt 2) { throw "Process sampling failed in $id" }
                $uptime = [double]::Parse(($snapshot[0] -split "`t")[1], [Globalization.CultureInfo]::InvariantCulture)
                $sampleTime = [DateTime]::UtcNow.ToString('o')
                $totalThreads = 0
                foreach ($line in $snapshot[1..($snapshot.Count-1)]) {
                    $fields = $line -split "`t", 7
                    if ($fields.Count -ne 7) { throw "Malformed process sample in $id" }
                    $key = "$id/$($fields[0])/$($fields[1])"
                    $ticks = [long]$fields[2]
                    $cpu = $null
                    $interval = $null
                    if ($previous.ContainsKey($key)) {
                        $interval = $uptime - $previous[$key].uptime
                        if ($interval -gt 0) { $cpu = [math]::Round(100 * ($ticks - $previous[$key].ticks) / $clockTicks / $interval, 4) }
                    }
                    $previous[$key] = @{uptime=$uptime;ticks=$ticks}
                    $totalThreads += [int]$fields[5]
                    @{timestamp=$sampleTime;container=$id;name=$prepared[$id];pid=[int]$fields[0];start_ticks=$fields[1];command=$fields[6];cpu_ticks=$ticks;cpu_percent=$cpu;cpu_interval_seconds=$interval;rss_bytes=([long]$fields[3]*$pageBytes);virtual_bytes=[long]$fields[4];threads=[int]$fields[5]} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'processes.jsonl')
                }
                $containerStats = $stats | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.ID -eq $id } | Select-Object -First 1
                if (!$containerStats) { throw "Missing container stats for $id" }
                @{timestamp=$timestamp;stats=$containerStats;threads=$totalThreads} | ConvertTo-Json -Depth 5 -Compress | Add-Content (Join-Path $OutputDir 'containers.jsonl')
                @{timestamp=$sampleTime;container=$id;threads=$totalThreads} | ConvertTo-Json -Compress | Add-Content (Join-Path $OutputDir 'threads.jsonl')
            }
        }
    }
    New-Item -ItemType File -Force (Join-Path $OutputDir 'collector-ready') | Out-Null
    if ($finalSample) { break }
    Start-Sleep -Seconds $IntervalSeconds
}
