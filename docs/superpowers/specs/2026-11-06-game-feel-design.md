# Game feel and synchronization

Approved direction: convincing, child-friendly physics; not a heavy simulation.

Preserve all 27 games and existing audio/design work on feature/global-game-visual-refresh. No merge to main. Audit each page individually; leave sound rules unchanged where verified correct. Changes must address evidenced defects, not pretend every game needs continuous physics.

1. Physics uses elapsed time, bounded substeps, circular hitboxes in screen-correct units, approach-only impulses, depenetration, and bounded bot acceleration. Rendering and collision geometry share dimensions. No energy boost for a separating contact.
2. Shot/turn animations are cancelable on reset, navigation, and disposal. Input locks synchronously before asynchronous work. Score commits at the displayed event, not before it.
3. Gameplay updates never await audio loading. Per-channel latest-event serialization prevents stale requests; result priority protects victory against lower-priority feedback. Stop/mute invalidates pending audio. Files must be verified in the final APK.
4. Touch cancellation clears drag state. Invalid moves receive gentle feedback; no duplicate scoring on rapid taps. Dense boards use compact headers without shrinking the actual field unnecessarily.
5. Record every game in a review matrix with defect/fix/verification, explicitly mark code-only review versus device testing. Run Flutter tests and analyze in CI and inspect the built APK. No claim of device/audio-latency testing without a real run.

Alternative rejected: approximate coefficient tweaks retain geometry errors. Full simulation rewrite is excessive for board and learning games. Selected approach: focused repairs plus small shared physics/audio/cancellation utilities.
