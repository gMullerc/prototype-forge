param([string]$FlutterPath = '')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'foundry\tool\resolve-flutter.ps1')

$flutter = Resolve-FlutterCommand -ExplicitPath $FlutterPath
$dart = Resolve-DartCommand -FlutterCommand $flutter

$dartProjects = @(
    'foundry\packages\prototype_agent',
    'foundry\packages\prototype_export',
    'foundry\packages\prototype_gateway_protocol',
    'foundry\packages\prototype_gateway_client',
    'foundry\packages\prototype_tool_discovery',
    'foundry\packages\prototype_spec',
    'foundry\packages\prototype_runtime',
    'foundry\packages\prototype_workspace',
    'foundry\packages\prototype_material_exporter',
    'foundry\services\local_gateway'
)
$flutterProjects = @(
    'foundry\packages\prototype_flutter',
    'foundry\packages\prototype_material_catalog',
    'studio'
)

foreach ($project in $dartProjects) {
    $directory = Join-Path $PSScriptRoot $project
    Write-Host "`nValidando $project"
    Push-Location $directory
    try {
        & $dart pub get
        if ($LASTEXITCODE -ne 0) { throw "dart pub get falhou em $project" }
        & $dart analyze
        if ($LASTEXITCODE -ne 0) { throw "dart analyze falhou em $project" }
        & $dart test
        if ($LASTEXITCODE -ne 0) { throw "dart test falhou em $project" }
    }
    finally {
        Pop-Location
    }
}

foreach ($project in $flutterProjects) {
    $directory = Join-Path $PSScriptRoot $project
    Write-Host "`nValidando $project"
    Push-Location $directory
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou em $project" }
        & $flutter analyze
        if ($LASTEXITCODE -ne 0) { throw "flutter analyze falhou em $project" }
        & $flutter test
        if ($LASTEXITCODE -ne 0) { throw "flutter test falhou em $project" }
    }
    finally {
        Pop-Location
    }
}

$studioDirectory = Join-Path $PSScriptRoot 'studio'
Write-Host "`nCompilando Flutter Web"
Push-Location $studioDirectory
try {
    & $flutter build web
    if ($LASTEXITCODE -ne 0) { throw 'flutter build web falhou.' }
}
finally {
    Pop-Location
}

Write-Host "`nTodas as verificações passaram."
