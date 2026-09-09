param([string]$ProjectName = 'book-reviews-a3')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Invoke-Compose {
    param([string]$File, [string[]]$ComposeArguments)
    & docker compose -p $ProjectName -f $File @ComposeArguments
    if ($LASTEXITCODE -ne 0) { throw "Compose failed: $File $ComposeArguments" }
}

$configurations = @('compose.yaml', 'compose.cache.yaml', 'compose.search.yaml', 'compose.full.yaml')
foreach ($configuration in $configurations) {
    Invoke-Compose $configuration @('config', '--quiet')
    Write-Output "PASS: $configuration config"
}
Invoke-Compose 'compose.full.yaml' @('build', 'web')
foreach ($configuration in $configurations) {
    # Stop only this project's optional services so their absence is real.
    Invoke-Compose 'compose.full.yaml' @('stop', 'web', 'redis', 'opensearch')
    Invoke-Compose $configuration @('up', '-d', '--no-build')
    $ready = $false
    for ($attempt = 0; $attempt -lt 45; $attempt++) {
        try {
            $response = Invoke-WebRequest 'http://localhost:3000/up' -TimeoutSec 5
            if ($response.StatusCode -eq 200) { $ready = $true; break }
        } catch { Start-Sleep -Seconds 2 }
    }
    if (!$ready) { throw "FAIL: $configuration Rails startup" }
    foreach ($path in @('/books', '/authors', '/reports/author-statistics', '/reports/top-rated-books', '/reports/top-selling-books', '/book-search?q=architecture')) {
        $response = Invoke-WebRequest "http://localhost:3000$path" -TimeoutSec 30
        if ($response.StatusCode -ne 200) { throw "FAIL: $configuration $path" }
        Write-Output "PASS: $configuration GET $path"
    }
}
Write-Output 'PASS: all four deployments; full configuration remains running on localhost:3000'
