# Global Game Visual Refresh Design

## Intent

Modernize the appearance, color, hierarchy, and touch quality of all 27 games while preserving gameplay, scoring, navigation, and the completed semantic audio work. The result should feel like one internationally polished children's game collection, not 27 unrelated screens.

## Design direction

Use a modern playful Material 3 language: soft tinted backgrounds, high-contrast surfaces, rounded geometry, restrained gradients, clear feedback states, large touch targets, and light depth. Each game keeps a semantic palette suited to its theme while sharing the same shell and visual tokens.

## Goals

- Give every game a deliberate palette, background, header, board surface, control style, and result treatment.
- Improve readability, spacing, proportional balance, and one-handed mobile usability.
- Standardize AppBars, cards, buttons, chips, status panels, dialogs, and disabled/selected states.
- Keep game boards visually distinct and ensure gameplay objects remain immediately recognizable.
- Meet accessible contrast and minimum touch-target expectations.
- Avoid excessive animation, visual noise, and oversaturated full-screen backgrounds.

## Non-goals

- No changes to game rules, AI, physics, scores, saved progress, multiplayer, navigation structure, or audio mappings.
- No new third-party UI dependency and no generated decorative artwork that would increase APK size unnecessarily.
- No redesign of the application into a web-like dashboard.

## Approaches considered

1. **One identical theme for every game.** Fast and consistent, but removes the identity of sports, puzzle, strategy, and learning games.
2. **Independent redesign of every screen.** Maximum variety, but repeats code and recreates the current inconsistency.
3. **Shared design system with per-game semantic palettes (selected).** Central tokens and reusable surfaces provide consistency, while a palette registry gives each game its own personality.

## Visual system

- Introduce central spacing, radii, shadows, surface colors, gradients, and text roles.
- Introduce `GamePalette` definitions for sports, strategy, puzzle, memory, traditional, and learning experiences.
- Provide reusable widgets for a tinted page background, premium game AppBar, hero/status panel, surface card, score badge, and section title.
- Use subtle decorative background bubbles rendered in Flutter, with `IgnorePointer` and low opacity.
- Default touch targets are at least 48 logical pixels.
- Selected states combine color, border, icon, and elevation instead of color alone.
- Result states use semantic success, warning, and error colors consistently.

## Per-game treatment

- Sports and physics: deep arena surfaces with cyan/green accents, bright objects, and strong score contrast.
- Strategy boards: warm neutral boards, precise grids, restrained player colors, and clear selection halos.
- Traditional games: earth, amber, teal, and stone tones with tactile board surfaces.
- Puzzles and memory: violet, blue, coral, and emerald accents with calm neutral backgrounds.
- Learning games: bright but soft color families, oversized learning content, and gentle positive/error feedback.
- Letter coloring and cards: high-contrast white canvases, friendly gradient headers, and consistent tool palettes.

## Constraints and safety

- Responsive layouts must work on narrow phones without overflow.
- Existing CustomPainters keep their coordinate logic; only paints and surrounding chrome change.
- The refresh is delivered in one batch and verified with static contracts, Flutter analysis, and a release APK build.
