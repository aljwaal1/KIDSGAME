from pathlib import Path
import shutil

ROOT = Path.cwd()
SRC = Path(__file__).resolve().parent

FILES = [
    'lib/games/tic_tac_toe_page.dart',
    'lib/games/sliding_puzzle_page.dart',
    'lib/games/letter_bubbles_page.dart',
    'lib/screens/developer_page.dart',
    'lib/theme/app_theme.dart',
    'lib/widgets/mascot_painter.dart',
]

for rel in FILES:
    src = SRC / rel
    dst = ROOT / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
    print(f'✅ wrote {rel}')

print('\nتم تطبيق إصلاح KIDSGAME v3. الآن شغّل:')
print('flutter pub get')
print('flutter analyze --no-fatal-infos --no-fatal-warnings')
