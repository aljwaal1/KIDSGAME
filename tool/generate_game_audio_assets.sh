#!/usr/bin/env bash
set -euo pipefail

out="assets/sounds/game"
mkdir -p "$out"

tone() {
  local name="$1" freq="$2" duration="$3"
  [[ "$duration" == .* ]] && duration="0$duration"
  ffmpeg -hide_banner -loglevel error -y -f lavfi -i "sine=frequency=$freq:duration=$duration:sample_rate=22050" \
    -af "afade=t=in:d=0.008,afade=t=out:st=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.06}'):d=0.06,volume=0.48" -ac 1 -c:a pcm_s16le "$out/$name.wav"
}

chord() {
  local name="$1" f1="$2" f2="$3" f3="$4" duration="$5"
  [[ "$duration" == .* ]] && duration="0$duration"
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "sine=frequency=$f1:duration=$duration:sample_rate=22050" \
    -f lavfi -i "sine=frequency=$f2:duration=$duration:sample_rate=22050" \
    -f lavfi -i "sine=frequency=$f3:duration=$duration:sample_rate=22050" \
    -filter_complex "[0:a][1:a][2:a]amix=inputs=3:normalize=1,afade=t=in:d=0.012,afade=t=out:st=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.10}'):d=0.10,volume=0.75" \
    -ac 1 -c:a pcm_s16le "$out/$name.wav"
}

sweep() {
  local name="$1" f1="$2" f2="$3" duration="$4"
  [[ "$duration" == .* ]] && duration="0$duration"
  ffmpeg -hide_banner -loglevel error -y -f lavfi \
    -i "aevalsrc=0.42*sin(2*PI*($f1*t+(($f2-$f1)/(2*$duration))*t*t)):s=22050:d=$duration" \
    -af "afade=t=in:d=0.008,afade=t=out:st=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.08}'):d=0.08" -ac 1 -c:a pcm_s16le "$out/$name.wav"
}

hit() {
  local name="$1" cutoff="$2" duration="$3"
  [[ "$duration" == .* ]] && duration="0$duration"
  ffmpeg -hide_banner -loglevel error -y -f lavfi -i "anoisesrc=color=pink:duration=$duration:sample_rate=22050:amplitude=.65" \
    -af "lowpass=f=$cutoff,afade=t=out:st=0.015:d=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.015}'),volume=.62" -ac 1 -c:a pcm_s16le "$out/$name.wav"
}

tone ui_select 780 .09
tone ui_tap 620 .07
tone piece_select 520 .08
hit piece_move 1100 .15
hit piece_drop 720 .18
hit piece_capture 520 .24
chord piece_promote 660 830 990 .42
sweep card_flip 1450 620 .17
chord card_match 720 910 1080 .34
hit tile_slide 1250 .15
hit draw_line 2100 .11
chord box_complete 520 700 880 .30
hit dice_roll 1750 .46
tone token_step 470 .08
sweep ladder_climb 350 1180 .55
sweep snake_slide 1050 240 .58
chord bubble_pop 620 940 1250 .15
chord correct 720 960 1200 .26
sweep gentle_error 430 300 .26
chord round_complete 620 830 1040 .52
chord victory 660 880 1320 .95
sweep defeat 480 190 .72
chord friend_victory 590 790 1180 .82
chord draw 410 520 620 .55
hit hockey_wall 1600 .08
hit hockey_paddle 900 .12
chord hockey_goal 440 660 990 .62
hit penalty_kick 700 .16
hit penalty_net 2400 .38
hit penalty_save 1000 .22
sweep marble_launch 260 920 .20
hit marble_roll 1500 .24
sweep soft_miss 360 290 .23
sweep throw 320 1100 .24
hit stone_crash 650 .46
tone stone_pickup 580 .08
hit stone_place 900 .14
hit blocked 420 .12
sweep reveal 420 850 .28
chord treasure 740 1110 1480 .50
hit trace 2200 .10

echo "generated $(find "$out" -type f -name '*.wav' | wc -l) original WAV assets"
