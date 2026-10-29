#!/usr/bin/env bash
set -euo pipefail

mapfile -t games < <(find lib/games -maxdepth 1 -name '*_page.dart' -printf '%f\n' | sort)
test "${#games[@]}" = "27"

if rg -n "SoundService\.instance\.play\('[^']+\.wav'" lib/games; then
  echo "raw game sound filenames remain" >&2
  exit 1
fi

require() {
  local file="$1" event="$2"
  rg -q "GameSoundEvent\.$event" "lib/games/$file"
}

require air_hockey_page.dart hockeyWallHit
require air_hockey_page.dart hockeyPaddleHit
require penalty_shootout_page.dart penaltyKick
require penalty_shootout_page.dart penaltyNet
require penalty_shootout_page.dart penaltySave
require checkers_page.dart pieceCapture
require dots_and_boxes_page.dart boxComplete
require memory_pairs_page.dart cardFlip
require smart_maze_page.dart blockedMove
require snakes_and_ladders_page.dart diceRoll
require snakes_and_ladders_page.dart ladderClimb
require snakes_and_ladders_page.dart snakeSlide
require tic_tac_toe_page.dart drawResult
require letter_bubbles_page.dart bubblePop
rg -q "playEvent" lib/screens/developer_page.dart

echo "per-game semantic audio mappings: PASS (27 games)"
