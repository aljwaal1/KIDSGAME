from pathlib import Path
import shutil

ROOT = Path.cwd()
SRC = Path(__file__).resolve().parent

files = [
    'lib/main.dart',
    'lib/screens/home_page.dart',
    'lib/screens/developer_page.dart',
    'lib/services/score_service.dart',
    'lib/services/sound_service.dart',
    'lib/theme/app_theme.dart',
    'lib/widgets/mascot_painter.dart',
    'lib/games/tic_tac_toe_page.dart',
    'lib/games/sliding_puzzle_page.dart',
    'lib/games/letter_bubbles_page.dart',
    'lib/games/memory_pairs_page.dart',
    'lib/games/pattern_challenge_page.dart',
    'lib/games/mini_sudoku_page.dart',
    'lib/games/smart_maze_page.dart',
    'lib/games/quick_math_page.dart',
]

for rel in files:
    src = SRC / rel
    dst = ROOT / rel
    if not src.exists():
        raise FileNotFoundError(f'Missing in hotfix package: {rel}')
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

# Safety patch: remove any Dart dot-shorthand patterns if an older generated file remains elsewhere.
main_path = ROOT / 'lib' / 'main.dart'
main = main_path.read_text(encoding='utf-8')
replacements = {
    'textDirection: .rtl': 'textDirection: TextDirection.rtl',
    'clipBehavior: .antiAlias': 'clipBehavior: Clip.antiAlias',
    'MainAxisAlignment.spaceBetween': 'MainAxisAlignment.spaceBetween',
}
for a, b in replacements.items():
    main = main.replace(a, b)
main_path.write_text(main, encoding='utf-8')

print('KIDSGAME hotfix v4 applied successfully.')
print('Now run: flutter pub get')
print('Then run: flutter analyze --no-fatal-infos --no-fatal-warnings')
