#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! grep -Eq '^    - assets/sounds/game/ *$' pubspec.yaml; then
  echo 'FAIL: game sound directory is not declared in pubspec.yaml' >&2
  exit 1
fi
if [[ $# -gt 0 ]]; then
  entries=$(unzip -Z1 "$1")
  count=0
  while IFS= read -r asset; do
    entry="assets/flutter_assets/assets/sounds/$asset"
    if ! grep -Fxq "$entry" <<< "$entries"; then
      echo "FAIL: missing packaged sound: $asset" >&2
      exit 1
    fi
    cmp "assets/sounds/$asset" <(unzip -p "$1" "$entry")
    count=$((count + 1))
  done < <(rg -o 'game/[a-z_]+\.wav' lib/services/game_audio_catalog.dart | sort -u)
  echo "packaged game audio: PASS ($count files, byte-identical)"
else
  echo 'game audio asset declaration: PASS'
fi
