#!/usr/bin/env bash

set -Eeuo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_directory/foundry/tool/resolve-flutter.sh"

flutter_command="$(resolve_flutter "${1:-${FLUTTER_PATH:-}}")"
dart_command="$(resolve_dart "$flutter_command")"
gateway_directory="$script_directory/foundry/services/local_gateway"
runtime_directory="$script_directory/.runtime"
gateway_host="${PROTOTYPE_GATEWAY_HOST:-127.0.0.1}"
gateway_port="${PROTOTYPE_GATEWAY_PORT:-8790}"
gateway_url="http://${gateway_host}:${gateway_port}"
workspace_directory="${PROTOTYPE_WORKSPACE:-$script_directory}"
shutdown_token="$(uuidgen 2>/dev/null || printf '%s-%s\n' "$$" "$(date +%s)")"
gateway_pid=""
owns_gateway=false

if [[ ! -d "$gateway_directory" ]]; then
  echo "Gateway não encontrado em $gateway_directory" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl é necessário para verificar o gateway local." >&2
  exit 1
fi

flutter_version="$("$flutter_command" --version | head -n 1)"
echo "Usando $flutter_version"
if [[ "$flutter_version" != Flutter\ 3.24.* ]]; then
  echo "Aviso: a baseline homologada é Flutter 3.24.x." >&2
fi

gateway_is_healthy() {
  curl --silent --fail --max-time 2 "$gateway_url/v1/health" >/dev/null 2>&1
}

cleanup() {
  local exit_code=$?

  if [[ "$owns_gateway" == true && -n "$gateway_pid" ]] && kill -0 "$gateway_pid" 2>/dev/null; then
    curl --silent --fail --max-time 3 \
      -X POST "$gateway_url/internal/shutdown" \
      -H "x-prototype-shutdown-token: $shutdown_token" >/dev/null 2>&1 || true

    for _ in {1..20}; do
      if ! kill -0 "$gateway_pid" 2>/dev/null; then
        break
      fi
      sleep 0.25
    done

    if kill -0 "$gateway_pid" 2>/dev/null; then
      kill "$gateway_pid" 2>/dev/null || true
    fi
  fi

  exit "$exit_code"
}
trap cleanup EXIT INT TERM

if ! gateway_is_healthy; then
  mkdir -p "$runtime_directory"
  (
    cd "$gateway_directory"
    "$dart_command" pub get
    PROTOTYPE_GATEWAY_SHUTDOWN_TOKEN="$shutdown_token" \
      PROTOTYPE_WORKSPACE="$workspace_directory" \
      "$dart_command" run bin/local_gateway.dart \
      >"$runtime_directory/gateway.stdout.log" \
      2>"$runtime_directory/gateway.stderr.log"
  ) &
  gateway_pid=$!
  owns_gateway=true

  gateway_ready=false
  for ((attempt = 1; attempt <= 80; attempt++)); do
    if gateway_is_healthy; then
      gateway_ready=true
      break
    fi
    if ! kill -0 "$gateway_pid" 2>/dev/null; then
      break
    fi
    sleep 0.25
  done

  if [[ "$gateway_ready" != true ]]; then
    if [[ -f "$runtime_directory/gateway.stderr.log" ]]; then
      cat "$runtime_directory/gateway.stderr.log" >&2
    fi
    echo "O gateway local não iniciou em até 20 segundos." >&2
    exit 1
  fi
fi

cd "$script_directory/studio"
"$flutter_command" pub get
"$flutter_command" run -d chrome \
  --dart-define="PROTOTYPE_GATEWAY_URL=$gateway_url"
