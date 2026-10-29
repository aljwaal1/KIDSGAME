# KIDSGAME Professional Audio Review Design

## Intent

Review every game from its real code paths and give each meaningful event an appropriate, reliable sound. The work must improve clarity and enjoyment without changing rules, scoring, AI, layouts, navigation, or visual behavior.

## Current findings

- The app has 27 game pages and only eight shared non-voice effects: `click`, `tap`, `move`, `pop`, `chime`, `wrong`, and `win` (with `click` also used as a dice sound).
- A single game-effects player stops its current sound whenever another game sound begins. This cuts off fast sequences and makes unrelated events compete.
- Celebration and UI channels are separated, but collision, movement, result, and voice are not fully separated.
- Air hockey can request the same collision sound many times per second.
- Penalty shootout has no kick, net, post, or goalkeeper-save sound in the current `main` branch.
- Letter activities mix bundled WAV files and device TTS inconsistently. Some pages use only TTS even though bundled letter recordings exist.
- A player who loses against the bot can hear the same positive win sound used for a human victory.
- Draws and neutral round endings often have no distinct feedback.

## Goals

1. Audit and update all 27 games individually.
2. Use semantic events instead of raw filenames in game pages.
3. Add distinct, child-friendly effects where the actual game event warrants them.
4. Prevent clipping, unwanted interruption, and rapid repeated playback.
5. Keep all audio offline and keep APK growth controlled.
6. Make Arabic and English letter pronunciation predictable across supported Android devices.
7. Add automated checks for missing assets and invalid mappings.

## Non-goals

- No changes to game rules, scoring, bot strength, visuals, navigation, or layout.
- No background music in this phase.
- No online audio or runtime downloads.
- No spoken narration for ordinary games.

## Chosen approach

Use a central semantic audio system with per-game profiles. Game code requests events such as `penaltyKick`, `hockeyPaddleHit`, `pieceCapture`, `correctAnswer`, or `humanVictory`; the service resolves the correct asset, channel, volume, priority, cooldown, and interruption policy.

Rejected alternatives:

- Direct filename replacement in every page: faster but preserves fragile duplication.
- Procedural sound generation: small but too synthetic for the requested quality.

## Audio architecture

### Channels

- UI: navigation, mode changes, selection.
- Action: moves, flips, throws, drawing, rolling.
- Impact: collisions, captures, goals, falling pieces.
- Result: correct, wrong, round complete, draw, victory, defeat.
- Voice: bundled letter recordings first, TTS fallback second.

### Playback policy

- UI sounds may interrupt only UI sounds.
- Action and impact sounds use separate players so a move can be followed by an impact without truncation.
- Result sounds have higher priority than action sounds.
- Voice ducks effects briefly and is never cut off by a UI click.
- Repeated physics effects receive per-event cooldowns and optional pitch/volume variation.
- Muting stops every channel including TTS.
- High, medium, and low use one consistent level curve, while each asset retains a calibrated base gain.

## Per-game review and design

| Game | Verified current events | Required professional mapping |
|---|---|---|
| Air hockey | wall hit, paddle hit, goal, match finish | soft wall rebound; sharper paddle strike; dedicated goal horn; human victory/opponent victory; 70–100 ms collision cooldown |
| Animal picture puzzle | picture/difficulty selection, tile selection, tile swap, solved | quiet selection; tile lift; wooden swap; puzzle-complete flourish |
| Arabic letter cards | next/previous card and TTS | bundled Arabic letter WAV first; TTS fallback; no click competing with pronunciation |
| Arabic letter coloring | stroke completion, clear, next, previous, spoken letter | soft drawing trace; completion sparkle; navigation tick; bundled pronunciation then TTS; win sound must finish without masking the letter |
| English capital coloring | trace progress, completion, clear, navigation, spoken letter | soft tracing sound with cooldown; completion flourish; bundled English letter WAV first; TTS fallback; remove competing click before speech |
| Checkers | piece move, capture, promotion, chained capture, victory | piece slide; distinct capture; crown/promotion chime; final victory or defeat based on winner |
| Connect Four | mode selection, disc drop, line completion | plastic disc drop; stack impact; four-in-row flourish; human victory/opponent victory/draw |
| Dahdel | launch, rolling repeats, boundary contact, hit/capture, miss | marble launch; controlled rolling loop/pulses; stone/marble impact; capture flourish; gentle miss; cooldown tied to actual motion speed |
| Dots and boxes | line draw, box completion, extra turn, board finish | pencil/line stroke; box stamp; multi-box escalation; victory/draw; avoid generic tap/pop overlap |
| English letter cards | next/previous card and TTS | bundled English WAV first; TTS fallback; voice channel owns playback; quiet navigation only after/before safe gap |
| Letter bubbles | bubble tap, correct pop, wrong selection, target completed, Arabic speech | bubble pop; soft error; round-complete sparkle; selected and target letters use bundled WAV first; effects duck under speech |
| Memory pairs | card flip, pair match, mismatch, board complete | card flip; pair match sparkle; gentle mismatch; full-board completion; no harsh wrong sound for young children |
| Mini Sudoku | number placement, correct placement, wrong placement, solved | keypad tick; correct cell tone; restrained error; puzzle-complete flourish |
| Odd one out | correct and wrong selection, next round | correct discovery tone; gentle wrong tone; short transition; reserve full win for a milestone, not each answer |
| Pattern challenge | correct and wrong pattern choice | pattern-confirm tone; gentle error; difficulty-neutral feedback without full celebration each tap |
| Pebble Harra | invalid pit, pebble selection/distribution, capture, game finish | pebble pick; sequential drops; capture scoop; human victory/opponent victory; no positive `pop` for player defeat |
| Penalty shootout | kick animation, goal/save result, match finish | dedicated ball kick at animation start; net hit for goal; glove/save impact for save; optional post sound if event exists later; crowd result; human victory/opponent victory |
| Quick math | correct/wrong answer | bright short correct tone; soft error; streak escalation only when streak data exists; no generic pop |
| Ring guess | correct hand, wrong hand, round transition | reveal/whoosh; small treasure sparkle for correct; neutral miss; avoid full match-victory sound each round |
| Seega | placement, selection, invalid move, move, capture, victory | stone place; stone select; blocked move; stone slide; capture clack; human victory/opponent victory |
| Sequence ordering | reset/selection, item swap, correct sequence, wrong check | card pickup; reorder slide; completion flourish; restrained check error |
| Seven stones | ball throw, miss, tower hit, stone pickup/place, rebuild error, tower complete | throw whoosh; stone crash; soft miss; pickup; placement; invalid placement; rebuild victory flourish |
| Shape and shadow | correct/wrong choice | shape snap; gentle mismatch; short round transition; no generic system chime |
| Sliding puzzle | difficulty selection, tile move, solved | tile slide with small variations; invalid move remains silent; solved flourish |
| Smart maze | wall collision, valid step, exit reached | soft blocked bump; footstep/tile move with cooldown; exit flourish |
| Snakes and ladders | dice roll, token steps, ladder, snake, victory | real dice roll/land; token step cadence; rising ladder glissando; descending snake slide; human victory/opponent victory |
| Tic-tac-toe | mode selection, X/O placement, win line, draw | separate X and O placement timbres; line-complete flourish; human victory/opponent victory; distinct draw ending |

## Asset strategy

- Reuse one asset only when the physical/semantic event is genuinely the same.
- Add compact mono assets at an appropriate sample rate and trim leading/trailing silence.
- Normalize perceived loudness by category, not merely peak amplitude.
- Keep effects short; longer result sounds remain on the result channel.
- Preserve the existing 54 Arabic/English letter files, validate them, and use them before TTS.
- Assets must be original/generated for the project or clearly licensed for redistribution.

## Tests and verification

- Unit test every semantic event mapping and channel/policy.
- Asset-manifest test: every mapped file exists and every shipped non-voice effect is mapped or explicitly documented.
- Cooldown tests for air hockey and rolling/physics events.
- Priority tests: result sounds are not truncated by UI/action sounds.
- Mute/level persistence tests.
- Voice tests for bundled-file success and TTS fallback.
- Static audit confirming every game page uses semantic events and no raw game-effect filenames remain.
- `flutter analyze`, `flutter test`, and release APK build.
- Manual smoke checklist for all 27 games on the APK, focusing on action/result synchronization.

## Acceptance criteria

- Each of the 27 games has a documented and implemented event map.
- No important event uses an unrelated generic sound.
- Rapid collisions do not produce audio spam.
- Human victory, opponent victory, and draw are distinguishable where applicable.
- Voice remains clear and respects the global sound level/mute state.
- No game logic or visual regression is introduced.
- Release APK builds successfully and contains every referenced asset.
