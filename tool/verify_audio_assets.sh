#!/usr/bin/env bash
set -euo pipefail

mapfile -t assets < <(rg -o "game/[a-z_]+\.wav" lib/services/game_audio_catalog.dart | sort -u)
test "${#assets[@]}" -ge 30

for asset in "${assets[@]}"; do
  path="assets/sounds/$asset"
  test -s "$path"
  test "$(od -An -tx1 -N4 "$path" | tr -d ' \n')" = "52494646"
  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$path")
  awk -v d="$duration" 'BEGIN { exit !(d > 0 && d < 3.0) }'
  channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=nw=1:nk=1 "$path")
  test "$channels" = "1"
done

echo "audio assets: PASS (${#assets[@]} files)"
