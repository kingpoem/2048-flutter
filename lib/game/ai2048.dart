import 'dart:math' as math;

import 'game2048.dart';

/// Expectimax AI ported from [nneonneo/2048-ai](https://github.com/nneonneo/2048-ai).
///
/// Uses a 64-bit bitboard (each cell = 4-bit nibble storing log2(tile value)),
/// precomputed move/heuristic lookup tables, and expectimax search with
/// transposition caching.
class Ai2048 {
  Ai2048._();

  static const int rowMask = 0xFFFF;
  static const int colMask = 0x000F000F000F000F;

  static const double scoreLostPenalty = 200000.0;
  static const double scoreMonotonicityPower = 4.0;
  static const double scoreMonotonicityWeight = 47.0;
  static const double scoreSumPower = 3.5;
  static const double scoreSumWeight = 11.0;
  static const double scoreMergesWeight = 700.0;
  static const double scoreEmptyWeight = 270.0;

  static const double cprobThreshBase = 0.0001;
  static const int cacheDepthLimit = 15;

  static bool _initialized = false;
  static late List<int> _rowLeftTable;
  static late List<int> _rowRightTable;
  static late List<int> _colUpTable;
  static late List<int> _colDownTable;
  static late List<double> _heurScoreTable;
  static late List<double> _scoreTable;

  static void ensureInitialized() {
    if (_initialized) return;
    _initTables();
    _initialized = true;
  }

  /// Convert a game grid (actual tile values) to a bitboard.
  static int gridToBoard(List<List<int>> grid) {
    var board = 0;
    var i = 0;
    for (final row in grid) {
      for (final value in row) {
        board |= _valueToRank(value) << (4 * i);
        i++;
      }
    }
    return board;
  }

  /// Convert a bitboard back to a game grid.
  static List<List<int>> boardToGrid(int board) {
    final grid = List.generate(4, (_) => List<int>.filled(4, 0));
    var i = 0;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        grid[r][c] = _rankToValue((board >> (4 * i)) & 0xF);
        i++;
      }
    }
    return grid;
  }

  /// Find the best move index: 0=up, 1=down, 2=left, 3=right. Returns -1 if none.
  static int findBestMove(int board) {
    ensureInitialized();

    var best = 0.0;
    var bestMove = -1;

    for (var move = 0; move < 4; move++) {
      final score = _scoreToplevelMove(board, move);
      if (score > best) {
        best = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// Find the best [Direction] for the given grid.
  static Direction? findBestDirection(List<List<int>> grid) {
    final move = findBestMove(gridToBoard(grid));
    return move < 0 ? null : _moveToDirection(move);
  }

  static int executeMove(int move, int board) {
    ensureInitialized();
    switch (move) {
      case 0:
        return _executeMove0(board);
      case 1:
        return _executeMove1(board);
      case 2:
        return _executeMove2(board);
      case 3:
        return _executeMove3(board);
      default:
        return ~0;
    }
  }

  static int _valueToRank(int value) {
    if (value <= 0) return 0;
    return (math.log(value) / math.ln2).round();
  }

  static int _rankToValue(int rank) {
    if (rank <= 0) return 0;
    return 1 << rank;
  }

  static Direction _moveToDirection(int move) {
    switch (move) {
      case 0:
        return Direction.up;
      case 1:
        return Direction.down;
      case 2:
        return Direction.left;
      case 3:
        return Direction.right;
      default:
        throw ArgumentError('Invalid move index: $move');
    }
  }

  static int _reverseRow(int row) {
    return ((row >> 12) & 0xF) |
        ((row >> 4) & 0xF0) |
        ((row << 4) & 0xF00) |
        ((row << 12) & 0xF000);
  }

  static int _unpackCol(int row) {
    final tmp = row;
    return (tmp |
            (tmp << 12) |
            (tmp << 24) |
            (tmp << 36)) &
        colMask;
  }

  static int _transpose(int x) {
    var a1 = x & 0xF0F00F0FF0F00F0F;
    var a2 = x & 0x0000F0F00000F0F0;
    var a3 = x & 0x0F0F00000F0F0000;
    var a = a1 | (a2 << 12) | (a3 >> 12);
    final b1 = a & 0xFF00FF0000FF00FF;
    final b2 = a & 0x00FF00FF00000000;
    final b3 = a & 0x00000000FF00FF00;
    return b1 | (b2 >> 24) | (b3 << 24);
  }

  static int _countEmpty(int x) {
    x |= (x >> 2) & 0x3333333333333333;
    x |= (x >> 1);
    x = (~x) & 0x1111111111111111;
    x += x >> 32;
    x += x >> 16;
    x += x >> 8;
    x += x >> 4;
    return x & 0xF;
  }

  static int _countDistinctTiles(int board) {
    var bitset = 0;
    var b = board;
    while (b != 0) {
      bitset |= 1 << (b & 0xF);
      b >>= 4;
    }
    bitset >>= 1;
    var count = 0;
    while (bitset != 0) {
      bitset &= bitset - 1;
      count++;
    }
    return count;
  }

  static void _initTables() {
    _rowLeftTable = List<int>.filled(65536, 0);
    _rowRightTable = List<int>.filled(65536, 0);
    _colUpTable = List<int>.filled(65536, 0);
    _colDownTable = List<int>.filled(65536, 0);
    _heurScoreTable = List<double>.filled(65536, 0);
    _scoreTable = List<double>.filled(65536, 0);

    for (var row = 0; row < 65536; row++) {
      final line = <int>[
        (row >> 0) & 0xF,
        (row >> 4) & 0xF,
        (row >> 8) & 0xF,
        (row >> 12) & 0xF,
      ];

      var score = 0.0;
      for (final rank in line) {
        if (rank >= 2) {
          score += (rank - 1) * (1 << rank);
        }
      }
      _scoreTable[row] = score;

      var sum = 0.0;
      var empty = 0;
      var merges = 0;
      var prev = 0;
      var counter = 0;
      for (final rank in line) {
        sum += math.pow(rank, scoreSumPower).toDouble();
        if (rank == 0) {
          empty++;
        } else {
          if (prev == rank) {
            counter++;
          } else if (counter > 0) {
            merges += 1 + counter;
            counter = 0;
          }
          prev = rank;
        }
      }
      if (counter > 0) {
        merges += 1 + counter;
      }

      var monotonicityLeft = 0.0;
      var monotonicityRight = 0.0;
      for (var i = 1; i < 4; i++) {
        if (line[i - 1] > line[i]) {
          monotonicityLeft += math.pow(line[i - 1], scoreMonotonicityPower) -
              math.pow(line[i], scoreMonotonicityPower);
        } else {
          monotonicityRight += math.pow(line[i], scoreMonotonicityPower) -
              math.pow(line[i - 1], scoreMonotonicityPower);
        }
      }

      _heurScoreTable[row] = scoreLostPenalty +
          scoreEmptyWeight * empty +
          scoreMergesWeight * merges -
          scoreMonotonicityWeight *
              math.min(monotonicityLeft, monotonicityRight) -
          scoreSumWeight * sum;

      final working = List<int>.from(line);
      for (var i = 0; i < 3; i++) {
        var j = i + 1;
        for (; j < 4; j++) {
          if (working[j] != 0) break;
        }
        if (j == 4) break;

        if (working[i] == 0) {
          working[i] = working[j];
          working[j] = 0;
          i--;
        } else if (working[i] == working[j]) {
          if (working[i] != 0xF) {
            working[i]++;
          }
          working[j] = 0;
        }
      }

      final result = (working[0] << 0) |
          (working[1] << 4) |
          (working[2] << 8) |
          (working[3] << 12);
      final revResult = _reverseRow(result);
      final revRow = _reverseRow(row);

      _rowLeftTable[row] = row ^ result;
      _rowRightTable[revRow] = revRow ^ revResult;
      _colUpTable[row] = _unpackCol(row) ^ _unpackCol(result);
      _colDownTable[revRow] = _unpackCol(revRow) ^ _unpackCol(revResult);
    }
  }

  static int _executeMove0(int board) {
    var ret = board;
    final t = _transpose(board);
    ret ^= _colUpTable[(t >> 0) & rowMask] << 0;
    ret ^= _colUpTable[(t >> 16) & rowMask] << 4;
    ret ^= _colUpTable[(t >> 32) & rowMask] << 8;
    ret ^= _colUpTable[(t >> 48) & rowMask] << 12;
    return ret;
  }

  static int _executeMove1(int board) {
    var ret = board;
    final t = _transpose(board);
    ret ^= _colDownTable[(t >> 0) & rowMask] << 0;
    ret ^= _colDownTable[(t >> 16) & rowMask] << 4;
    ret ^= _colDownTable[(t >> 32) & rowMask] << 8;
    ret ^= _colDownTable[(t >> 48) & rowMask] << 12;
    return ret;
  }

  static int _executeMove2(int board) {
    var ret = board;
    ret ^= _rowLeftTable[(board >> 0) & rowMask] << 0;
    ret ^= _rowLeftTable[(board >> 16) & rowMask] << 16;
    ret ^= _rowLeftTable[(board >> 32) & rowMask] << 32;
    ret ^= _rowLeftTable[(board >> 48) & rowMask] << 48;
    return ret;
  }

  static int _executeMove3(int board) {
    var ret = board;
    ret ^= _rowRightTable[(board >> 0) & rowMask] << 0;
    ret ^= _rowRightTable[(board >> 16) & rowMask] << 16;
    ret ^= _rowRightTable[(board >> 32) & rowMask] << 32;
    ret ^= _rowRightTable[(board >> 48) & rowMask] << 48;
    return ret;
  }

  static double _scoreHelper(int board, List<double> table) {
    return table[(board >> 0) & rowMask] +
        table[(board >> 16) & rowMask] +
        table[(board >> 32) & rowMask] +
        table[(board >> 48) & rowMask];
  }

  static double _scoreHeurBoard(int board) {
    return _scoreHelper(board, _heurScoreTable) +
        _scoreHelper(_transpose(board), _heurScoreTable);
  }

  static double _scoreToplevelMove(int board, int move) {
    final newBoard = executeMove(move, board);
    if (board == newBoard) return 0;

    final state = _EvalState(depthLimit: math.max(3, _countDistinctTiles(board) - 2));
    return _scoreTilechooseNode(state, newBoard, 1.0) + 1e-6;
  }

  static double _scoreTilechooseNode(_EvalState state, int board, double cprob) {
    if (cprob < cprobThreshBase || state.curDepth >= state.depthLimit) {
      state.maxDepth = math.max(state.curDepth, state.maxDepth);
      return _scoreHeurBoard(board);
    }

    if (state.curDepth < cacheDepthLimit) {
      final cached = state.transTable[board];
      if (cached != null && cached.depth <= state.curDepth) {
        state.cacheHits++;
        return cached.heuristic;
      }
    }

    final numOpen = _countEmpty(board);
    cprob /= numOpen;

    var res = 0.0;
    var tmp = board;
    var tile2 = 1;
    while (tile2 != 0) {
      if ((tmp & 0xF) == 0) {
        res += _scoreMoveNode(state, board | tile2, cprob * 0.9) * 0.9;
        res += _scoreMoveNode(state, board | (tile2 << 1), cprob * 0.1) * 0.1;
      }
      tmp >>= 4;
      tile2 <<= 4;
    }
    res /= numOpen;

    if (state.curDepth < cacheDepthLimit) {
      state.transTable[board] = _TransTableEntry(state.curDepth, res);
    }

    return res;
  }

  static double _scoreMoveNode(_EvalState state, int board, double cprob) {
    var best = 0.0;
    state.curDepth++;
    for (var move = 0; move < 4; move++) {
      final newBoard = executeMove(move, board);
      state.movesEvaled++;
      if (board != newBoard) {
        best = math.max(best, _scoreTilechooseNode(state, newBoard, cprob));
      }
    }
    state.curDepth--;
    return best;
  }
}

class _TransTableEntry {
  const _TransTableEntry(this.depth, this.heuristic);

  final int depth;
  final double heuristic;
}

class _EvalState {
  _EvalState({required this.depthLimit});

  final Map<int, _TransTableEntry> transTable = {};
  int maxDepth = 0;
  int curDepth = 0;
  int cacheHits = 0;
  int movesEvaled = 0;
  final int depthLimit;
}

/// Top-level helper for [compute] / isolates.
Direction? findBestDirectionForGrid(List<List<int>> grid) {
  Ai2048.ensureInitialized();
  return Ai2048.findBestDirection(grid);
}
