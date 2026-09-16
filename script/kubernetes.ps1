param(
    [ValidateSet('create', 'deploy', 'status')][string]$Action = 'deploy',
    [string]$ClusterName = 'book-reviews-a4',
    [string]$Context = 'k3d-book-reviews-a4',
    [string]$K3d = "$PSScriptRoot/../tmp/tools/k3d.exe",
    [int]$HttpPort = 8080,
    [int]$HttpsPort = 8443
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Kube {
    param([string[]]$Arguments)
    & kubectl --context $Context @Arguments
    if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $($Arguments -join ' ')" }
}
if ($Action -eq 'create') {
    if (!(Test-Path $K3d)) { throw 'Install k3d or provide -K3d path/to/k3d.exe (see script/assignment4-commands.txt).' }
    & $K3d cluster create $ClusterName --servers 1 --agents 0 --image rancher/k3s:v1.31.5-k3s1 --port "${HttpPort}:30080@server:0" --port "${HttpsPort}:30443@server:0" --k3s-arg '--disable=traefik@server:0' --wait
    if ($LASTEXITCODE -ne 0) { throw 'k3d cluster creation failed' }
    return
}
if ($Action -eq 'status') {
    Kube @('-n', 'book-reviews', 'get', 'pods,svc,ingress,pvc')
    return
}

if (!(Test-Path tmp/edge/tls/tls.crt)) { throw 'Run ./script/edge.ps1 init first.' }
$values = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^([A-Z_]+)=(.*)$') { $values[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'") }
}
foreach ($key in @('DB_USERNAME', 'DB_PASSWORD', 'SECRET_KEY_BASE')) {
    if (!$values[$key]) { throw "Missing $key in .env" }
}
$appHost = if ($values['APP_HOST']) { $values['APP_HOST'] } else { 'app.localhost' }
$uploadPath = if ($values['UPLOADS_PATH']) { $values['UPLOADS_PATH'] } else { '/rails/storage' }
if ($uploadPath -notmatch '^/[a-zA-Z0-9_/-]+$') { throw 'UPLOADS_PATH must be an absolute Linux directory.' }

& docker build -t book-reviews:assignment4 .
if ($LASTEXITCODE -ne 0) { throw 'Image build failed' }
if ($Context -like 'k3d-*') {
    & $K3d image import book-reviews:assignment4 -c $ClusterName
    if ($LASTEXITCODE -ne 0) { throw 'k3d image import failed' }
} else {
    & minikube -p $Context image load book-reviews:assignment4
    if ($LASTEXITCODE -ne 0) { throw 'minikube image load failed' }
}

$nodes = (Kube @('get', 'nodes', '-o', 'json') | ConvertFrom-Json).items
if ($nodes.Count -ne 1) { throw 'This local storage configuration requires a single-node cluster.' }
Kube @('label', 'node', $nodes[0].metadata.name, 'book-reviews-storage=true', '--overwrite')
New-Item -ItemType Directory -Force k8s/generated | Out-Null
New-Item -ItemType Directory -Force tmp/edge/kubernetes | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding $false
$secret = @{ apiVersion='v1'; kind='Secret'; metadata=@{name='book-reviews-secrets';namespace='book-reviews'}; type='Opaque'; stringData=@{} }
foreach ($key in @('DB_USERNAME', 'DB_PASSWORD', 'SECRET_KEY_BASE')) { $secret.stringData[$key] = $values[$key] }
# Preserve existing cluster/database credentials when they have already been materialized.
if (!(Test-Path k8s/secret.yaml)) { [IO.File]::WriteAllText((Join-Path (Get-Location) 'k8s/secret.yaml'), ($secret | ConvertTo-Json -Depth 8), $utf8) }
$tls = Kube @('create', 'secret', 'tls', 'book-reviews-tls', '-n', 'book-reviews', '--cert=tmp/edge/tls/tls.crt', '--key=tmp/edge/tls/tls.key', '--dry-run=client', '-o', 'json')
[IO.File]::WriteAllText((Join-Path (Get-Location) 'k8s/generated/tls.yaml'), ($tls -join "`n"), $utf8)

# Generate only configuration overrides; reusable base manifests remain in k8s/.
$patches = @(
    @{ target=@{kind='ConfigMap';name='book-reviews-config'}; patch=(@{apiVersion='v1';kind='ConfigMap';metadata=@{name='book-reviews-config'};data=@{APP_HOST=$appHost;UPLOADS_PATH=$uploadPath}} | ConvertTo-Json -Depth 10) },
    @{ target=@{kind='Ingress';name='book-reviews'}; patch=(@(@{op='replace';path='/spec/rules/0/host';value=$appHost},@{op='replace';path='/spec/tls/0/hosts/0';value=$appHost}) | ConvertTo-Json -Depth 10) }
)
foreach ($name in @('book-reviews-web', 'book-reviews-static')) {
    $patches += @{target=@{kind='Deployment';name=$name};patch=(ConvertTo-Json -InputObject @(@{op='replace';path='/spec/template/spec/containers/0/volumeMounts/0/mountPath';value=$uploadPath}) -Depth 10)}
}
$patches += @{target=@{kind='Deployment';name='book-reviews-traefik'};patch=(ConvertTo-Json -InputObject @(@{op='replace';path='/spec/template/spec/containers/0/args/1';value="--entrypoints.web.http.redirections.entrypoint.to=:$HttpsPort"}) -Depth 10)}
$overlay = @{apiVersion='kustomize.config.k8s.io/v1beta1';kind='Kustomization';resources=@('../../../k8s');patches=$patches}
[IO.File]::WriteAllText((Join-Path (Get-Location) 'tmp/edge/kubernetes/kustomization.yaml'), ($overlay | ConvertTo-Json -Depth 20), $utf8)

Kube @('apply', '-f', 'k8s/namespace.yaml')
foreach ($file in @('configmap.yaml','secret.yaml','postgres-pvc.yaml','postgres-service.yaml','postgres-deployment.yaml','shared-pvcs.yaml','redis-service.yaml','redis-deployment.yaml','opensearch-service.yaml','opensearch-deployment.yaml')) {
    Kube @('apply', '-f', "k8s/$file")
}
Kube @('-n','book-reviews','rollout','status','deployment/book-reviews-postgres','--timeout=300s')
Kube @('-n','book-reviews','delete','job','book-reviews-prepare','--ignore-not-found')
Kube @('apply','-f','k8s/prepare-job.yaml')
Kube @('-n','book-reviews','wait','--for=condition=complete','job/book-reviews-prepare','--timeout=300s')
Kube @('apply','-k','tmp/edge/kubernetes')
Kube @('-n','book-reviews','rollout','restart','deployment/book-reviews-web','deployment/book-reviews-static')
foreach ($deployment in @('redis','opensearch','web','static','traefik')) {
    Kube @('-n','book-reviews','rollout','status',"deployment/book-reviews-$deployment",'--timeout=300s')
}
Kube @('-n','book-reviews','exec','deployment/book-reviews-web','-c','rails','--','bin/rails','search:reindex')
Write-Output "Ready: https://${appHost}:$HttpsPort (k3d). For Minikube forward the Traefik service ports."
