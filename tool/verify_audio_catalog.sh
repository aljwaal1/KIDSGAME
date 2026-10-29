#!/usr/bin/env bash
set -euo pipefail

catalog="lib/services/game_audio_catalog.dart"
events="lib/services/game_audio_event.dart"

test -f "$catalog"
test -f "$events"
rg -q "enum GameSoundEvent" "$events"
rg -q "GameAudioCue cueFor" "$catalog"
rg -q "Future<bool> playEvent" lib/services/sound_service.dart

for channel in ui action impact result voice; do
  rg -q "AudioChannel\.$channel" "$catalog" lib/services/sound_service.dart
done

echo "audio catalog contract: PASS"
