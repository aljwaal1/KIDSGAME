KIDSGAME final sequence cleanup

This hotfix does two things:
1. Replaces lib/games/sequence_order_page.dart with a clean valid Dart implementation.
2. Overwrites accidental root-level games/sequence_order_page.dart with a harmless placeholder, so flutter analyze will not analyze a broken duplicate file.

Upload this ZIP over the current project only. Do not upload older hotfix files again.
