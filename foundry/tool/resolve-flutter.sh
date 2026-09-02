#!/usr/bin/env bash

resolve_flutter() {
  local explicit_path="${1:-}"

  if [[ -n "$explicit_path" ]]; then
    if [[ -x "$explicit_path" ]]; then
      printf '%s\n' "$explicit_path"
      return 0
    fi

    echo "Flutter não é executável em: $explicit_path" >&2
    return 1
  fi

  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return 0
  fi

  local candidate
  for candidate in \
    "$HOME/development/flutter/bin/flutter" \
    "$HOME/flutter/bin/flutter" \
    "/opt/homebrew/share/flutter/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Flutter não foi encontrado. Adicione flutter ao PATH ou informe o caminho como primeiro argumento." >&2
  return 1
}

resolve_dart() {
  local flutter_command="$1"
  local flutter_bin
  flutter_bin="$(cd "$(dirname "$flutter_command")" && pwd)"
  local bundled_dart="$flutter_bin/cache/dart-sdk/bin/dart"

  if [[ -x "$bundled_dart" ]]; then
    printf '%s\n' "$bundled_dart"
    return 0
  fi

  if command -v dart >/dev/null 2>&1; then
    command -v dart
    return 0
  fi

  echo "Dart não foi encontrado no SDK Flutter selecionado nem no PATH." >&2
  return 1
}
