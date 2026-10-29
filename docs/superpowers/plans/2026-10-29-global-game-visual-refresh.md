# Global Game Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the design, color, hierarchy, responsiveness, and touch quality of all 27 games without altering gameplay or audio.

**Architecture:** Add a dependency-free shared Flutter design system containing semantic palettes, tokens, themed backgrounds, headers, surfaces, and badges. Apply it first through the global Material theme and then explicitly to every game family, retaining CustomPainter geometry while upgrading paints and surrounding chrome.

**Tech Stack:** Flutter, Dart, Material 3, existing CustomPainter code, shell verification contracts.

**Spec:** `docs/superpowers/specs/2026-10-29-global-game-visual-refresh-design.md`

## Global Constraints

- Preserve all game rules, AI, physics, scoring, navigation, persistence, and semantic audio mappings.
- Add no third-party UI dependency.
- Keep responsive layouts safe on narrow phones.
- Keep touch targets at least 48 logical pixels.
- Use semantic feedback and accessible contrast; do not communicate selection by color alone.

## Review Focus

- Narrow phones: headers, boards, and control rows must not overflow at 320 logical pixels.
- Long Arabic strings: status text must wrap or ellipsize without hiding primary controls.
- Dense boards: decoration must not reduce playable board area or obscure pieces.
- State clarity: selected, disabled, correct, wrong, winner, and current-player states must remain distinguishable.
- Performance: decorative layers must ignore input and avoid repainting game logic unnecessarily.

---

### Task 1: Shared visual system

**Files:**
- Create: `lib/theme/game_design_system.dart`
- Modify: `lib/theme/app_theme.dart`
- Create: `tool/verify_game_visual_system.sh`

**Interfaces:**
- Produces: `GamePalette`, `GamePalettes`, `GameBackdrop`, `GameHeroPanel`, `GameSurface`, `GameBadge`, and updated Material component themes.

- [ ] Write a failing static contract asserting palette coverage, reusable widgets, 48px controls, and Material component themes.
- [ ] Run the contract and confirm it fails because the design system does not exist.
- [ ] Implement shared tokens, palettes, surfaces, backgrounds, and global theme roles.
- [ ] Run the contract and existing audio contracts; expect PASS.
- [ ] Commit the shared visual foundation.

### Task 2: Sports and physics games

**Files:**
- Modify: `lib/games/air_hockey_page.dart`
- Modify: `lib/games/penalty_shootout_page.dart`
- Modify: `lib/games/dahdel_page.dart`
- Modify: `lib/games/seven_stones_page.dart`

**Interfaces:**
- Consumes: the shared backdrop, palette, hero, surface, and badge APIs from Task 1.

- [ ] Add failing mapping assertions for a deliberate sports palette on all four pages.
- [ ] Apply arena/field backgrounds, clearer score hierarchy, consistent controls, and polished board paints without changing coordinates.
- [ ] Run visual and audio contracts; expect PASS.
- [ ] Commit sports and physics visuals.

### Task 3: Strategy and traditional board games

**Files:**
- Modify: `lib/games/tic_tac_toe_page.dart`
- Modify: `lib/games/checkers_page.dart`
- Modify: `lib/games/connect_four_page.dart`
- Modify: `lib/games/dots_and_boxes_page.dart`
- Modify: `lib/games/seega_page.dart`
- Modify: `lib/games/pebble_harra_page.dart`
- Modify: `lib/games/ring_guess_page.dart`
- Modify: `lib/games/snakes_and_ladders_page.dart`

**Interfaces:**
- Consumes: shared design APIs; preserves all board indices and gesture handlers.

- [ ] Add failing assertions for palette and themed-surface coverage on all eight pages.
- [ ] Upgrade selection halos, board frames, turn/status panels, player chips, and result contrast.
- [ ] Run all contracts; expect PASS.
- [ ] Commit strategy and traditional visuals.

### Task 4: Puzzle, memory, and reasoning games

**Files:**
- Modify: `lib/games/animal_picture_puzzle_page.dart`
- Modify: `lib/games/sliding_puzzle_page.dart`
- Modify: `lib/games/memory_pairs_page.dart`
- Modify: `lib/games/mini_sudoku_page.dart`
- Modify: `lib/games/smart_maze_page.dart`
- Modify: `lib/games/pattern_challenge_page.dart`
- Modify: `lib/games/sequence_order_page.dart`
- Modify: `lib/games/odd_one_out_page.dart`
- Modify: `lib/games/shape_shadow_page.dart`

**Interfaces:**
- Consumes: shared design APIs; keeps puzzle data and completion behavior unchanged.

- [ ] Add failing coverage assertions for all nine pages.
- [ ] Apply calm backgrounds, consistent puzzle frames, card elevation, state borders, and responsive spacing.
- [ ] Run all contracts; expect PASS.
- [ ] Commit puzzle and reasoning visuals.

### Task 5: Letter, coloring, and learning games

**Files:**
- Modify: `lib/games/arabic_letter_cards_page.dart`
- Modify: `lib/games/english_letter_cards_page.dart`
- Modify: `lib/games/arabic_letter_coloring_page.dart`
- Modify: `lib/games/capital_letter_coloring_page.dart`
- Modify: `lib/games/letter_bubbles_page.dart`
- Modify: `lib/games/quick_math_page.dart`

**Interfaces:**
- Consumes: shared learning palettes and surfaces; keeps bundled pronunciation and drawing logic unchanged.

- [ ] Add failing coverage assertions for all six pages.
- [ ] Standardize learning canvases, tool palettes, answer states, letter cards, and instructional hierarchy.
- [ ] Run all contracts; expect PASS.
- [ ] Commit learning-game visuals.

### Task 6: Application shell, final audit, and APK

**Files:**
- Modify: `lib/screens/home_page.dart`
- Modify: `lib/main.dart`
- Modify: `tool/verify_game_visual_system.sh`

**Interfaces:**
- Consumes: all completed visual APIs and page mappings.
- Produces: one consistent app shell and a release APK.

- [ ] Audit every game filename against palette coverage and ensure no game page is omitted.
- [ ] Improve navigation, home cards, focus/pressed states, and reduced-motion behavior.
- [ ] Run `git diff --check` and all visual/audio verification scripts.
- [ ] Push a feature branch, run Flutter analyze and release APK build in CI, and fix any reported issue.
- [ ] Merge only after a green build, inspect the APK archive, and provide the direct APK file.
