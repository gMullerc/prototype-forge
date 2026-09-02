#!/usr/bin/env bash

set -Eeuo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_directory/foundry/tool/resolve-flutter.sh"

flutter_command="$(resolve_flutter "${1:-${FLUTTER_PATH:-}}")"
flutter_version="$($flutter_command --version | head -n 1)"
if [[ "$flutter_version" == Flutter\ 3.24.* ]]; then
  echo "OK Flutter: $flutter_version"
else
  echo "ERRO Flutter incompatível: $flutter_version" >&2
  echo 'A baseline do MVP é Flutter 3.24.x.' >&2
  exit 1
fi

dart_command="$(resolve_dart "$flutter_command")"
echo "OK Dart: $($dart_command --version 2>&1 | head -n 1)"

if command -v opencode >/dev/null 2>&1; then
  echo "OK OpenCode: $(opencode --version 2>&1 | head -n 1)"
else
  echo 'AVISO OpenCode não encontrado; o Motor local continua disponível.' >&2
fi

gateway_host="${PROTOTYPE_GATEWAY_HOST:-127.0.0.1}"
gateway_port="${PROTOTYPE_GATEWAY_PORT:-8790}"
if curl --silent --fail --max-time 2 "http://${gateway_host}:${gateway_port}/v1/health" >/dev/null 2>&1; then
  echo "OK Gateway local: http://${gateway_host}:${gateway_port}"
else
  echo 'AVISO Gateway local não está em execução; run-local.sh iniciará o processo.' >&2
fi

echo 'Ambiente compatível com o MVP.'
