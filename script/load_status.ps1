param([Parameter(Mandatory=$true)][string]$ResultsDir)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$matrix = Get-Content (Join-Path $ResultsDir 'matrix.json') -Raw | ConvertFrom-Json
$cases = @(Get-ChildItem -LiteralPath $ResultsDir -Directory | Where-Object { $_.Name -match '^(full|scaled)-(static|aggregation|search|book)-\d+$' })
$complete = @($cases | Where-Object { Test-Path (Join-Path $_.FullName 'completed.json') })
$active = $cases | Where-Object { !(Test-Path (Join-Path $_.FullName 'completed.json')) } | Sort-Object CreationTime -Descending | Select-Object -First 1
[pscustomobject]@{
    Status = $matrix.status
    Completed = "$($complete.Count)/$($matrix.totalCases)"
    ActiveCase = $active.Name
    DurationPerCaseSeconds = $matrix.durationSeconds
    ProcessId = $matrix.pid
    ProcessRunning = [bool](Get-Process -Id $matrix.pid -ErrorAction SilentlyContinue)
    Error = $matrix.error
    Results = $matrix.results
}
