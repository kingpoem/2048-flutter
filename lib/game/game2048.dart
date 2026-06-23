import 'dart:math';

enum Direction { up, down, left, right }

class Game2048 {
  static const size = 4;

  final Random _random = Random();
  List<List<int>> grid;
  int score;
  bool gameOver;
  List<(int, int)> lastMergedAt = [];
  (int, int)? lastSpawnedAt;

  Game2048()
      : grid = List.generate(size, (_) => List.filled(size, 0)),
        score = 0,
        gameOver = false {
    _spawnTile();
    _spawnTile();
  }

  void reset() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    gameOver = false;
    lastMergedAt = [];
    lastSpawnedAt = null;
    _spawnTile();
    _spawnTile();
  }

  bool move(Direction direction) {
    if (gameOver) return false;

    final before = _copyGrid();
    var gained = 0;
    lastMergedAt = [];
    lastSpawnedAt = null;

    switch (direction) {
      case Direction.left:
        for (var r = 0; r < size; r++) {
          final merged = _mergeLine(grid[r]);
          gained += merged.$2;
          grid[r] = merged.$1;
          for (final col in merged.$3) {
            lastMergedAt.add((r, col));
          }
        }
      case Direction.right:
        for (var r = 0; r < size; r++) {
          final reversed = grid[r].reversed.toList();
          final merged = _mergeLine(reversed);
          gained += merged.$2;
          grid[r] = merged.$1.reversed.toList();
          for (final col in merged.$3) {
            lastMergedAt.add((r, size - 1 - col));
          }
        }
      case Direction.up:
        for (var c = 0; c < size; c++) {
          final line = [for (var r = 0; r < size; r++) grid[r][c]];
          final merged = _mergeLine(line);
          gained += merged.$2;
          for (var r = 0; r < size; r++) {
            grid[r][c] = merged.$1[r];
          }
          for (final row in merged.$3) {
            lastMergedAt.add((row, c));
          }
        }
      case Direction.down:
        for (var c = 0; c < size; c++) {
          final line = [for (var r = size - 1; r >= 0; r--) grid[r][c]];
          final merged = _mergeLine(line);
          gained += merged.$2;
          for (var r = 0; r < size; r++) {
            grid[size - 1 - r][c] = merged.$1[r];
          }
          for (final row in merged.$3) {
            lastMergedAt.add((size - 1 - row, c));
          }
        }
    }

    if (!_gridsEqual(before, grid)) {
      score += gained;
      _spawnTile();
      if (!_canMove()) gameOver = true;
      return true;
    }
    return false;
  }

  (List<int>, int, List<int>) _mergeLine(List<int> line) {
    final nums = line.where((n) => n != 0).toList();
    var gained = 0;
    final mergeIndices = <int>[];
    final merged = <int>[];

    for (var i = 0; i < nums.length; i++) {
      if (i + 1 < nums.length && nums[i] == nums[i + 1]) {
        final v = nums[i] * 2;
        merged.add(v);
        gained += v;
        mergeIndices.add(merged.length - 1);
        i++;
      } else {
        merged.add(nums[i]);
      }
    }

    while (merged.length < size) {
      merged.add(0);
    }
    return (merged, gained, mergeIndices);
  }

  void _spawnTile() {
    final empty = <(int, int)>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 0) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;

    final (r, c) = empty[_random.nextInt(empty.length)];
    grid[r][c] = _random.nextDouble() < 0.9 ? 2 : 4;
    lastSpawnedAt = (r, c);
  }

  bool _canMove() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = grid[r][c];
        if (v == 0) return true;
        if (c + 1 < size && grid[r][c + 1] == v) return true;
        if (r + 1 < size && grid[r + 1][c] == v) return true;
      }
    }
    return false;
  }

  List<List<int>> _copyGrid() =>
      [for (final row in grid) List<int>.from(row)];

  bool _gridsEqual(List<List<int>> a, List<List<int>> b) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }
}
