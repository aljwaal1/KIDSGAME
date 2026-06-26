from pathlib import Path
import shutil

ROOT = Path.cwd()
SRC = Path(__file__).resolve().parent

FILES = [
    'lib/main.dart',
    'lib/screens/home_page.dart',
    'lib/services/score_service.dart',
    'lib/services/sound_service.dart',
    'lib/games/memory_pairs_page.dart',
    'lib/games/pattern_challenge_page.dart',
    'lib/games/mini_sudoku_page.dart',
    'lib/games/smart_maze_page.dart',
    'lib/games/quick_math_page.dart',
]

for rel in FILES:
    src = SRC / rel
    dst = ROOT / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)

pub = ROOT / 'pubspec.yaml'
if pub.exists():
    text = pub.read_text(encoding='utf-8')
    text = text.replace('version: 1.1.0+2', 'version: 1.2.1+4')
    text = text.replace('version: 1.2.0+3', 'version: 1.2.1+4')
    # Keep current SDK constraint; no Dart 3.10 dot-shorthand syntax is used in this hotfix.
    pub.write_text(text, encoding='utf-8')

print('تم تطبيق إصلاح KIDSGAME v2 بنجاح.')
print('الآن شغّل: flutter analyze --no-fatal-infos --no-fatal-warnings')
