import 'package:flutter_test/flutter_test.dart';
import 'package:kids_games_arena/main.dart';

void main() {
  testWidgets('Kids Games Arena starts', (tester) async {
    await tester.pumpWidget(const KidsGamesArenaApp());
    expect(find.text('ملعب الأطفال'), findsOneWidget);
  });
}
