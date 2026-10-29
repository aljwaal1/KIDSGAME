# Professional Game Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every meaningful event in all 27 KIDSGAME games a verified, child-friendly, context-appropriate sound without altering game rules or visual behavior.

**Architecture:** Replace raw asset filenames in game pages with semantic `GameSoundEvent` requests. A central catalog resolves each event to an asset, channel, gain, priority, and cooldown; separate reusable players prevent unrelated effects from cutting one another off. Bundled letter recordings use a voice adapter before Android TTS fallback.

**Tech Stack:** Flutter/Dart, `audioplayers`, `flutter_tts`, `shared_preferences`, Flutter tests, compact mono WAV assets generated and normalized at build-authoring time.

**Spec:** `docs/superpowers/specs/2026-10-29-professional-game-audio-design.md`

## Global Constraints

- Do not change game rules, scoring, bot behavior, navigation, layout, or visual design.
- All runtime audio remains offline.
- Keep four global levels: high, medium, low, muted.
- A mute action must stop effects and voice.
- Bundled Arabic and English letter WAV files are preferred; TTS is fallback only.
- Human victory, opponent victory, and draw must be distinguishable where the game exposes those outcomes.
- Physics sounds must be rate-limited without suppressing legitimate distinct impacts.
- Every shipped sound must be original/generated for this project or redistributable.

## Review Focus

- Rapid physics collisions: repeated wall/paddle contacts must not create audio spam or starve goal sounds.
- Simultaneous action/result events: the result must play fully and not be cut off by the preceding action.
- Muted voice activities: neither bundled speech nor TTS may play while muted.
- Missing/corrupt asset: playback must fail safely, report diagnostics, and never break game input.
- Page disposal during delayed audio/TTS: callbacks must not speak or update disposed pages.

---

### Task 1: Semantic audio catalog and channel policy

**Files:**
- Create: `lib/services/game_audio_event.dart`
- Create: `lib/services/game_audio_catalog.dart`
- Modify: `lib/services/sound_service.dart`
- Test: `test/game_audio_catalog_test.dart`
- Test: `test/sound_service_policy_test.dart`

**Interfaces:**
- Produces: `enum GameSoundEvent`; immutable `GameAudioCue`; `GameAudioCatalog.cueFor(GameSoundEvent)`; `SoundService.playEvent(GameSoundEvent)`; `SoundService.stopVoiceAwareAudio()`; cooldown and channel routing.

- [ ] **Step 1: Write failing catalog tests** asserting every enum value has a non-empty asset, channel, gain in `0...1`, non-negative cooldown, and result priority above action priority.
- [ ] **Step 2: Run `flutter test test/game_audio_catalog_test.dart` and verify failure because the catalog does not exist.**
- [ ] **Step 3: Add `GameSoundEvent`, `GameAudioCue`, channel/priority enums, and the complete central mapping.**
- [ ] **Step 4: Write failing service-policy tests** for independent channels, high/medium/low/muted factors, cooldown rejection, result precedence, and safe playback failure.
- [ ] **Step 5: Refactor `SoundService`** to own UI/action/impact/result/voice-safe players, route `playEvent`, preserve `play(String)` temporarily for non-game compatibility, and expose mute state synchronously.
- [ ] **Step 6: Run both task tests and verify PASS.**
- [ ] **Step 7: Commit `feat: add semantic multi-channel game audio`.**

### Task 2: Original compact audio asset pack

**Files:**
- Create: `tool/generate_game_audio_assets.sh`
- Create/replace: `assets/sounds/game/*.wav`
- Test: `test/audio_asset_manifest_test.dart`

**Interfaces:**
- Consumes: asset names declared by `GameAudioCatalog`.
- Produces: normalized mono WAV files for UI, action, impact, correct/error, victory/defeat/draw, penalty, hockey, board, card, dice, ladder/snake, bubble, and stone events.

- [ ] **Step 1: Write a failing manifest test** that extracts all catalog assets, verifies each exists under `assets/sounds/`, has a WAV header, is non-empty, and has no orphan non-letter game asset unless allow-listed.
- [ ] **Step 2: Run `flutter test test/audio_asset_manifest_test.dart` and verify missing-asset failures.**
- [ ] **Step 3: Add the deterministic authoring script** using layered envelopes/noise/tones to create original source assets; keep runtime free of synthesis.
- [ ] **Step 4: Generate, trim, normalize, and inspect all files** with `ffprobe`; require mono PCM, bounded duration, and no zero-duration files.
- [ ] **Step 5: Run the manifest test and verify PASS.**
- [ ] **Step 6: Commit `feat: add original game-specific sound pack`.**

### Task 3: Sports and physics games

**Files:**
- Modify: `lib/games/air_hockey_page.dart`
- Modify: `lib/games/penalty_shootout_page.dart`
- Modify: `lib/games/dahdel_page.dart`
- Modify: `lib/games/seven_stones_page.dart`
- Test: `test/sports_audio_mapping_test.dart`

**Interfaces:**
- Consumes: `SoundService.playEvent(GameSoundEvent)` and catalog cooldowns.
- Produces: event-accurate sports/physics call sites with no raw WAV filenames.

- [ ] **Step 1: Write failing source-mapping tests** for hockey wall/paddle/goal, penalty kick/net/save/final result, Dahdel launch/roll/impact/miss, and seven-stones throw/crash/place/complete.
- [ ] **Step 2: Run the mapping test and verify failure on current generic calls.**
- [ ] **Step 3: Update air hockey** with wall/paddle distinction, cooldown-safe impacts, goal, human win, opponent win.
- [ ] **Step 4: Update penalty shootout** to trigger kick at animation start, net or goalkeeper-save at resolution, then correct match result.
- [ ] **Step 5: Update Dahdel** with launch, speed-gated rolling, collision/capture, and miss events.
- [ ] **Step 6: Update seven stones** with throw, miss, crash, pickup/place, invalid placement, and tower completion.
- [ ] **Step 7: Run the mapping test and relevant existing tests; verify PASS.**
- [ ] **Step 8: Commit `feat: tailor sports and physics game audio`.**

### Task 4: Strategy board games

**Files:**
- Modify: `lib/games/checkers_page.dart`
- Modify: `lib/games/connect_four_page.dart`
- Modify: `lib/games/dots_and_boxes_page.dart`
- Modify: `lib/games/pebble_harra_page.dart`
- Modify: `lib/games/seega_page.dart`
- Modify: `lib/games/tic_tac_toe_page.dart`
- Test: `test/strategy_audio_mapping_test.dart`

**Interfaces:**
- Consumes: semantic move/select/capture/drop/draw/result events.
- Produces: outcome-aware strategy game mappings.

- [ ] **Step 1: Write failing mapping tests** covering move/capture/promotion, disc drop, box completion, pebble distribution/capture, seega move/capture, X/O placement, victory/defeat/draw.
- [ ] **Step 2: Run the test and verify failure.**
- [ ] **Step 3: Update checkers** to distinguish selection, slide, capture, promotion, and final outcome.
- [ ] **Step 4: Update Connect Four and dots-and-boxes** to distinguish placement/drawing, local completion, draw, and winner outcome.
- [ ] **Step 5: Update Pebble Harra and Seega** to distinguish pebble/stone movement, invalid action, capture, human win, opponent win.
- [ ] **Step 6: Update tic-tac-toe** with distinct X/O placement and separate human victory, opponent victory, friend-game victory, and draw.
- [ ] **Step 7: Run mapping and existing tests; verify PASS.**
- [ ] **Step 8: Commit `feat: tailor strategy game audio`.**

### Task 5: Puzzle and memory games

**Files:**
- Modify: `lib/games/animal_picture_puzzle_page.dart`
- Modify: `lib/games/memory_pairs_page.dart`
- Modify: `lib/games/mini_sudoku_page.dart`
- Modify: `lib/games/sequence_order_page.dart`
- Modify: `lib/games/sliding_puzzle_page.dart`
- Modify: `lib/games/smart_maze_page.dart`
- Modify: `lib/games/snakes_and_ladders_page.dart`
- Test: `test/puzzle_audio_mapping_test.dart`

**Interfaces:**
- Consumes: select/flip/swap/step/blocked/dice/ladder/snake/result events.
- Produces: puzzle-specific event mappings without logic changes.

- [ ] **Step 1: Write failing mapping tests** for selection/swap/solve, flip/match/mismatch, Sudoku correct/error/solve, reorder/check, maze wall/step/exit, and dice/token/ladder/snake/outcome.
- [ ] **Step 2: Run the test and verify failure.**
- [ ] **Step 3: Update picture, sliding, sequence, and Sudoku pages** with tactile action sounds and restrained feedback.
- [ ] **Step 4: Update memory pairs** with card flip, match, gentle mismatch, board completion.
- [ ] **Step 5: Update smart maze** with blocked bump, rate-safe step, and exit flourish.
- [ ] **Step 6: Update snakes and ladders** with dice roll/land, token cadence, ladder rise, snake descent, and outcome-aware finish.
- [ ] **Step 7: Run mapping and existing tests; verify PASS.**
- [ ] **Step 8: Commit `feat: tailor puzzle and memory game audio`.**

### Task 6: Educational choice games

**Files:**
- Modify: `lib/games/odd_one_out_page.dart`
- Modify: `lib/games/pattern_challenge_page.dart`
- Modify: `lib/games/quick_math_page.dart`
- Modify: `lib/games/ring_guess_page.dart`
- Modify: `lib/games/shape_shadow_page.dart`
- Test: `test/learning_audio_mapping_test.dart`

**Interfaces:**
- Consumes: correct, gentle error, reveal, treasure, and round-transition events.
- Produces: short child-friendly learning feedback without treating each answer as a whole-game victory.

- [ ] **Step 1: Write failing mapping tests** for each correct/wrong/reveal path and assert no per-answer `humanVictory` event.
- [ ] **Step 2: Run the test and verify failure.**
- [ ] **Step 3: Replace generic win/pop/wrong calls** with game-appropriate correct, mismatch, reveal, and transition events.
- [ ] **Step 4: Run mapping and existing tests; verify PASS.**
- [ ] **Step 5: Commit `feat: improve educational game feedback audio`.**

### Task 7: Letter voice and coloring activities

**Files:**
- Create: `lib/services/letter_voice_service.dart`
- Modify: `lib/games/arabic_letter_cards_page.dart`
- Modify: `lib/games/english_letter_cards_page.dart`
- Modify: `lib/games/arabic_letter_coloring_page.dart`
- Modify: `lib/games/capital_letter_coloring_page.dart`
- Modify: `lib/games/letter_bubbles_page.dart`
- Test: `test/letter_voice_service_test.dart`
- Test: `test/letter_game_audio_mapping_test.dart`

**Interfaces:**
- Produces: `LetterVoiceService.speakArabic(String, {Duration delay})`; `speakEnglish(String, {Duration delay})`; `stop()`; bundled-file-first and injected TTS fallback behavior.

- [ ] **Step 1: Write failing voice-service tests** for Arabic/English filename resolution, bundled success, TTS fallback, mute suppression, and stop/dispose behavior.
- [ ] **Step 2: Run the tests and verify failure because the service does not exist.**
- [ ] **Step 3: Implement the shared letter voice service** with one-at-a-time requests, delayed-request cancellation, level-aware gain, and TTS fallback.
- [ ] **Step 4: Migrate Arabic/English cards and coloring pages** to the shared voice service; map drawing/navigation/completion effects without masking speech.
- [ ] **Step 5: Migrate letter bubbles** to bundled pronunciation, bubble/correct/error/round events, and voice ducking.
- [ ] **Step 6: Run voice and mapping tests; verify PASS.**
- [ ] **Step 7: Commit `feat: unify letter pronunciation and learning audio`.**

### Task 8: Whole-project audit and release verification

**Files:**
- Modify: `lib/screens/developer_page.dart`
- Modify: `README.md`
- Test: `test/no_raw_game_audio_test.dart`
- Test: all tests under `test/`

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: diagnostics UI for semantic cues, complete audit evidence, and release APK.

- [ ] **Step 1: Add a failing static audit test** asserting all 27 game files contain no `SoundService.instance.play('*.wav')` raw calls and every expected page is included in the audit list.
- [ ] **Step 2: Run the static audit and fix any remaining raw calls or missing outcome paths.**
- [ ] **Step 3: Update the developer diagnostics page** to preview cues by category and show the last playback error.
- [ ] **Step 4: Run `dart format lib test` and verify no formatting changes remain afterward.**
- [ ] **Step 5: Run `flutter analyze --no-fatal-infos --no-fatal-warnings`; require exit 0.**
- [ ] **Step 6: Run `flutter test`; require 0 failures.**
- [ ] **Step 7: Run the asset audit with `ffprobe` and require every mapped WAV to be readable, mono, and non-zero duration.**
- [ ] **Step 8: Run `flutter build apk --release --no-tree-shake-icons`; require exit 0 and `build/app/outputs/flutter-apk/app-release.apk`.**
- [ ] **Step 9: Verify APK as a ZIP, record SHA-256 and size, and smoke-check installation metadata.**
- [ ] **Step 10: Commit `test: verify complete professional game audio pass`.**

## Self-review result

- Spec coverage: all architecture, asset, per-game, voice, mute, cooldown, outcome, and release requirements map to Tasks 1–8.
- Type consistency: all game tasks consume the same `GameSoundEvent` and `SoundService.playEvent` interface from Task 1; voice pages consume `LetterVoiceService` from Task 7.
- Review focus coverage: physics cooldown in Tasks 1/3; event priority in Task 1; mute/voice and disposal in Task 7; corrupt assets in Tasks 1/2.
- Scope: one cohesive audio subsystem; task grouping follows game behavior so each group is independently reviewable.
