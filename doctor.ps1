param(
    [string]$FlutterPath = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'foundry\tool\resolve-flutter.ps1')

$failed = $false

try {
    $flutter = Resolve-FlutterCommand -ExplicitPath $FlutterPath
    $flutterVersion = (& $flutter --version | Select-Object -First 1)
    if ($flutterVersion -match '^Flutter 3\.24\.') {
        Write-Host "OK Flutter: $flutterVersion" -ForegroundColor Green
    }
    else {
        Write-Host "ERRO Flutter incompatível: $flutterVersion" -ForegroundColor Red
        Write-Host 'A baseline do MVP é Flutter 3.24.x.' -ForegroundColor Yellow
        $failed = $true
    }

    $dart = Resolve-DartCommand -FlutterCommand $flutter
    $dartVersion = (& $dart --version 2>&1 | Select-Object -First 1)
    Write-Host "OK Dart: $dartVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERRO SDK: $($_.Exception.Message)" -ForegroundColor Red
    $failed = $true
}

$opencode = Get-Command opencode -ErrorAction SilentlyContinue
if ($null -eq $opencode) {
    Write-Host 'AVISO OpenCode não encontrado; o Motor local continua disponível.' -ForegroundColor Yellow
}
else {
    try {
        $opencodeVersion = (& $opencode.Source --version 2>&1 | Select-Object -First 1)
        Write-Host "OK OpenCode: $opencodeVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "AVISO OpenCode encontrado, mas não foi possível ler a versão: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

$gatewayHost = if ($env:PROTOTYPE_GATEWAY_HOST) {
    $env:PROTOTYPE_GATEWAY_HOST
}
else {
    '127.0.0.1'
}
$gatewayPort = if ($env:PROTOTYPE_GATEWAY_PORT) {
    [int]$env:PROTOTYPE_GATEWAY_PORT
}
else {
    8790
}
try {
    $health = Invoke-RestMethod -Uri "http://${gatewayHost}:$gatewayPort/v1/health" -TimeoutSec 2
    if ($health.status -eq 'ok') {
        Write-Host "OK Gateway local: http://${gatewayHost}:$gatewayPort" -ForegroundColor Green
    }
    else {
        Write-Host 'AVISO Gateway respondeu, mas ainda não está saudável.' -ForegroundColor Yellow
    }
}
catch {
    Write-Host 'AVISO Gateway local não está em execução; run-local.ps1 iniciará o processo.' -ForegroundColor Yellow
}

if ($failed) {
    Write-Host 'Ambiente não está pronto para o MVP.' -ForegroundColor Red
    exit 1
}

Write-Host 'Ambiente compatível com o MVP.' -ForegroundColor Green
