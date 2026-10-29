#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
system="$root/lib/theme/game_design_system.dart"
theme="$root/lib/theme/app_theme.dart"

test -f "$system"

for symbol in \
  'class GamePalette' \
  'abstract final class GamePalettes' \
  'class GameBackdrop' \
  'class GameHeroPanel' \
  'class GameSurface' \
  'class GameBadge'; do
  grep -q "$symbol" "$system"
done

grep -q 'kMinInteractiveDimension' "$system"
grep -q 'filledButtonTheme' "$theme"
grep -q 'outlinedButtonTheme' "$theme"
grep -q 'navigationBarTheme' "$theme"
grep -q 'dialogTheme' "$theme"

for game in air_hockey_page penalty_shootout_page dahdel_page seven_stones_page; do
  file="$root/lib/games/$game.dart"
  grep -q 'GameBackdrop' "$file"
  grep -q 'GamePalettes\.' "$file"
  grep -q 'GameHeroPanel' "$file"
done

for game in tic_tac_toe_page checkers_page connect_four_page dots_and_boxes_page seega_page pebble_harra_page ring_guess_page snakes_and_ladders_page; do
  file="$root/lib/games/$game.dart"
  grep -q 'GameBackdrop' "$file"
  grep -q 'GamePalettes\.' "$file"
done

for game in animal_picture_puzzle_page sliding_puzzle_page memory_pairs_page mini_sudoku_page smart_maze_page pattern_challenge_page sequence_order_page odd_one_out_page shape_shadow_page; do
  file="$root/lib/games/$game.dart"
  grep -q 'GameBackdrop' "$file"
  grep -q 'GamePalettes\.' "$file"
done

for game in arabic_letter_cards_page english_letter_cards_page arabic_letter_coloring_page capital_letter_coloring_page letter_bubbles_page quick_math_page; do
  file="$root/lib/games/$game.dart"
  grep -q 'GameBackdrop' "$file"
  grep -q 'GamePalettes\.learning' "$file"
done

mapfile -t game_files < <(find "$root/lib/games" -maxdepth 1 -name '*_page.dart' | sort)
test "${#game_files[@]}" -eq 27
for file in "${game_files[@]}"; do
  grep -q 'GameBackdrop' "$file"
done

home="$root/lib/screens/home_page.dart"
grep -q 'GameBackdrop' "$home"
grep -q 'scrollDirection: Axis.horizontal' "$home"
grep -q 'disableAnimations' "$root/lib/main.dart"
grep -q 'AnimatedSwitcher' "$root/lib/main.dart"

echo 'shared game visual system: PASS'
