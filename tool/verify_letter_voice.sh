#!/usr/bin/env bash
set -euo pipefail

service="lib/services/letter_voice_service.dart"
test -f "$service"
rg -q "playArabic" "$service"
rg -q "playEnglish" "$service"

for file in arabic_letter_cards_page.dart arabic_letter_coloring_page.dart letter_bubbles_page.dart; do
  rg -q "LetterVoiceService.playArabic" "lib/games/$file"
done
for file in english_letter_cards_page.dart capital_letter_coloring_page.dart; do
  rg -q "LetterVoiceService.playEnglish" "lib/games/$file"
done

echo "letter voice bundled-first contract: PASS"
