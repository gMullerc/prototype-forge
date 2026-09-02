function Resolve-FlutterCommand {
    param([string]$ExplicitPath)

    if ($ExplicitPath) {
        $resolved = Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop
        return $resolved.Path
    }

    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $localCandidate = Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat'
    if (Test-Path -LiteralPath $localCandidate -PathType Leaf) {
        return $localCandidate
    }

    throw 'Flutter não foi encontrado. Informe -FlutterPath ou adicione flutter ao PATH.'
}

function Resolve-DartCommand {
    param([Parameter(Mandatory = $true)][string]$FlutterCommand)

    $flutterBin = Split-Path -Parent $FlutterCommand
    $candidate = Join-Path $flutterBin 'cache\dart-sdk\bin\dart.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return $candidate
    }

    $command = Get-Command dart -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw 'Dart não foi encontrado no SDK Flutter selecionado nem no PATH.'
}
