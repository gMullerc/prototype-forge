param(
    [string]$FlutterPath = '',
    [string]$GatewayHost = '',
    [int]$GatewayPort = 0
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'foundry\tool\resolve-flutter.ps1')

$flutter = Resolve-FlutterCommand -ExplicitPath $FlutterPath
$dart = Resolve-DartCommand -FlutterCommand $flutter
$appDirectory = Join-Path $PSScriptRoot 'studio'
$gatewayDirectory = Join-Path $PSScriptRoot 'foundry\services\local_gateway'
$runtimeDirectory = Join-Path $PSScriptRoot '.runtime'
$gatewayHost = if ($GatewayHost) {
    $GatewayHost
}
elseif ($env:PROTOTYPE_GATEWAY_HOST) {
    $env:PROTOTYPE_GATEWAY_HOST
}
else {
    '127.0.0.1'
}
$gatewayPort = if ($GatewayPort -gt 0) {
    $GatewayPort
}
elseif ($env:PROTOTYPE_GATEWAY_PORT) {
    [int]$env:PROTOTYPE_GATEWAY_PORT
}
else {
    8790
}
if ($gatewayPort -lt 1 -or $gatewayPort -gt 65535) {
    throw "GatewayPort deve estar entre 1 e 65535: $gatewayPort"
}
$gatewayUrl = "http://${gatewayHost}:${gatewayPort}"
$gatewayProcess = $null
$ownsGateway = $false
$shutdownToken = [guid]::NewGuid().ToString('N')

if (-not (Test-Path -LiteralPath $appDirectory -PathType Container)) {
    throw "Aplicação não encontrada em $appDirectory"
}
if (-not (Test-Path -LiteralPath $gatewayDirectory -PathType Container)) {
    throw "Gateway não encontrado em $gatewayDirectory"
}

$version = (& $flutter --version | Select-Object -First 1)
Write-Host "Usando $version"
if ($version -notmatch '^Flutter 3\.24\.') {
    Write-Warning 'A baseline homologada é Flutter 3.24.x.'
}

function Test-GatewayHealthy {
    try {
        $health = Invoke-RestMethod -Uri "$gatewayUrl/v1/health" -TimeoutSec 2
        return $health.status -eq 'ok'
    }
    catch {
        return $false
    }
}

try {
    if (-not (Test-GatewayHealthy)) {
        New-Item -ItemType Directory -Path $runtimeDirectory -Force | Out-Null
        Push-Location $gatewayDirectory
        try {
            & $dart pub get
            if ($LASTEXITCODE -ne 0) { throw 'dart pub get falhou no gateway.' }
        }
        finally {
            Pop-Location
        }

        $previousToken = $env:PROTOTYPE_GATEWAY_SHUTDOWN_TOKEN
        $previousWorkspace = $env:PROTOTYPE_WORKSPACE
        $previousGatewayHost = $env:PROTOTYPE_GATEWAY_HOST
        $previousGatewayPort = $env:PROTOTYPE_GATEWAY_PORT
        $env:PROTOTYPE_GATEWAY_SHUTDOWN_TOKEN = $shutdownToken
        $env:PROTOTYPE_GATEWAY_HOST = $gatewayHost
        $env:PROTOTYPE_GATEWAY_PORT = "$gatewayPort"
        if ([string]::IsNullOrWhiteSpace($env:PROTOTYPE_WORKSPACE)) {
            $env:PROTOTYPE_WORKSPACE = $PSScriptRoot
        }
        try {
            $gatewayProcess = Start-Process `
                -FilePath $dart `
                -ArgumentList @('run', 'bin/local_gateway.dart') `
                -WorkingDirectory $gatewayDirectory `
                -WindowStyle Hidden `
                -RedirectStandardOutput (Join-Path $runtimeDirectory 'gateway.stdout.log') `
                -RedirectStandardError (Join-Path $runtimeDirectory 'gateway.stderr.log') `
                -PassThru
        }
        finally {
            if ($null -eq $previousToken) {
                Remove-Item Env:PROTOTYPE_GATEWAY_SHUTDOWN_TOKEN -ErrorAction SilentlyContinue
            }
            else {
                $env:PROTOTYPE_GATEWAY_SHUTDOWN_TOKEN = $previousToken
            }
            if ($null -eq $previousWorkspace) {
                Remove-Item Env:PROTOTYPE_WORKSPACE -ErrorAction SilentlyContinue
            }
            else {
                $env:PROTOTYPE_WORKSPACE = $previousWorkspace
            }
            if ($null -eq $previousGatewayHost) {
                Remove-Item Env:PROTOTYPE_GATEWAY_HOST -ErrorAction SilentlyContinue
            }
            else {
                $env:PROTOTYPE_GATEWAY_HOST = $previousGatewayHost
            }
            if ($null -eq $previousGatewayPort) {
                Remove-Item Env:PROTOTYPE_GATEWAY_PORT -ErrorAction SilentlyContinue
            }
            else {
                $env:PROTOTYPE_GATEWAY_PORT = $previousGatewayPort
            }
        }
        $ownsGateway = $true

        $ready = $false
        foreach ($attempt in 1..80) {
            if (Test-GatewayHealthy) {
                $ready = $true
                break
            }
            if ($gatewayProcess.HasExited) { break }
            Start-Sleep -Milliseconds 250
        }
        if (-not $ready) {
            $errorLog = Join-Path $runtimeDirectory 'gateway.stderr.log'
            if (Test-Path -LiteralPath $errorLog) { Get-Content -LiteralPath $errorLog }
            throw 'O gateway local não iniciou em até 20 segundos.'
        }
    }

    Push-Location $appDirectory
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get falhou.' }

        & $flutter run -d chrome "--dart-define=PROTOTYPE_GATEWAY_URL=$gatewayUrl"
        if ($LASTEXITCODE -ne 0) { throw 'flutter run falhou.' }
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($ownsGateway -and $null -ne $gatewayProcess -and -not $gatewayProcess.HasExited) {
        try {
            Invoke-WebRequest `
                -Uri "$gatewayUrl/internal/shutdown" `
                -Method Post `
                -Headers @{ 'x-prototype-shutdown-token' = $shutdownToken } `
                -TimeoutSec 3 | Out-Null
        }
        catch {}

        if (-not $gatewayProcess.WaitForExit(5000)) {
            Stop-Process -Id $gatewayProcess.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
