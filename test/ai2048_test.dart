import 'package:dart2048/game/ai2048.dart';
import 'package:dart2048/game/game2048.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(Ai2048.ensureInitialized);

  test('grid and board round-trip', () {
    const grid = [
      [2, 4, 8, 16],
      [0, 2, 4, 8],
      [0, 0, 2, 4],
      [0, 0, 0, 2],
    ];
    final board = Ai2048.gridToBoard(grid);
    expect(Ai2048.boardToGrid(board), grid);
  });

  test('executeMove left merges tiles', () {
    const grid = [
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ];
    final result = Ai2048.boardToGrid(Ai2048.executeMove(2, Ai2048.gridToBoard(grid)));
    expect(result[0], [4, 0, 0, 0]);
  });

  test('findBestDirection returns a valid move on playable board', () {
    const grid = [
      [2, 0, 0, 0],
      [0, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ];
    final direction = Ai2048.findBestDirection(grid);
    expect(direction, isNotNull);
    expect(Direction.values, contains(direction));
  });

  test('findBestMove returns -1 when no move is possible', () {
    const grid = [
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ];
    expect(Ai2048.findBestMove(Ai2048.gridToBoard(grid)), -1);
  });
}
