param(
    [ValidateSet('init', 'up', 'down', 'status', 'test')][string]$Action = 'up',
    [ValidateSet('single', 'proxy', 'full', 'scaled')][string]$Deployment = 'scaled',
    [string]$ProjectName = 'book-reviews-a4'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$root = (Get-Location).Path

function Invoke-Docker {
    param([string[]]$Arguments)
    & docker @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Docker failed: $($Arguments -join ' ')" }
}

if ($Action -eq 'init') {
    if (!(Test-Path .env)) { Copy-Item .env.example .env }
    $values = @{}
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([A-Z_]+)=(.*)$') { $values[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'") }
    }
    if (!$values['SECRET_KEY_BASE']) {
        $bytes = New-Object byte[] 64
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($bytes)
        $rng.Dispose()
        $secret = -join ($bytes | ForEach-Object { $_.ToString('x2') })
        Add-Content .env "`nSECRET_KEY_BASE=$secret" -Encoding ascii
    }
    $appHost = if ($values['APP_HOST']) { $values['APP_HOST'] } else { 'app.localhost' }
    New-Item -ItemType Directory -Force tmp/edge/tls | Out-Null
    Invoke-Docker @('run', '--rm', '--entrypoint', 'ruby', '-e', "APP_HOST=$appHost", '--mount', "type=bind,source=$root,target=/workspace", 'ruby:3.3.8-slim', '/workspace/script/generate_tls.rb', '/workspace/tmp/edge/tls')
    Write-Output 'Initialized .env secret and tmp/edge/tls. Private keys stay ignored.'
    return
}

$compose = @('compose', '--env-file', '.env', '-p', $ProjectName, '-f', "compose/compose.$Deployment.yaml")
switch ($Action) {
    'up' {
        if (!(Test-Path tmp/edge/tls/tls.crt)) { throw 'Run ./script/edge.ps1 init first.' }
        Invoke-Docker ($compose + @('config', '--quiet'))
        Invoke-Docker ($compose + @('build', 'web'))
        # Re-run schema preparation before replicas start after an image update.
        Invoke-Docker ($compose + @('run', '--rm', 'prepare'))
        Invoke-Docker ($compose + @('up', '-d', '--wait', '--wait-timeout', '240'))
    }
    'down' { Invoke-Docker ($compose + @('down')) }
    'status' { Invoke-Docker ($compose + @('ps')) }
    'test' {
        Invoke-Docker @('compose', '--env-file', '.env', '-p', "$ProjectName-tests", '-f', 'compose.yaml', 'build', 'web')
        Invoke-Docker @('compose', '--env-file', '.env', '-p', "$ProjectName-tests", '-f', 'compose.yaml', 'run', '--rm', '-e', 'RAILS_ENV=test', '-e', 'PARALLEL_WORKERS=2', 'web', 'bin/rails', 'test')
    }
}
