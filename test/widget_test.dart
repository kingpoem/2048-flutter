import 'package:flutter_test/flutter_test.dart';

import 'package:dart2048/game/game2048.dart';
import 'package:dart2048/main.dart';

void main() {
  testWidgets('2048 app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GameApp());
    expect(find.text('进化 2048'), findsOneWidget);
    expect(find.text('进化度'), findsOneWidget);
  });

  test('merge line works', () {
    final game = Game2048();
    game.grid = [
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ];
    game.score = 0;
    game.gameOver = false;

    expect(game.move(Direction.left), isTrue);
    expect(game.grid[0][0], 4);
    expect(game.score, 4);
  });
}
