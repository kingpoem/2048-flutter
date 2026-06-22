import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/game2048.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEDC22E)),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();
  late Game2048 _game;

  @override
  void initState() {
    super.initState();
    _game = Game2048();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _move(Direction direction) {
    setState(() => _game.move(direction));
  }

  void _newGame() {
    setState(() => _game.reset());
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(Direction.up);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _move(Direction.down);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _move(Direction.left);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _move(Direction.right);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: AppBar(
        title: const Text('2048'),
        backgroundColor: const Color(0xFFEDC22E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _newGame,
            child: const Text('新游戏', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          onVerticalDragEnd: (details) {
            final dy = details.primaryVelocity ?? 0;
            if (dy.abs() < 100) return;
            _move(dy < 0 ? Direction.up : Direction.down);
          },
          onHorizontalDragEnd: (details) {
            final dx = details.primaryVelocity ?? 0;
            if (dx.abs() < 100) return;
            _move(dx < 0 ? Direction.left : Direction.right);
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScoreBar(score: _game.score, gameOver: _game.gameOver),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final gap = 8.0;
                          final cell = (constraints.maxWidth - gap * 5) / 4;
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBBADA0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              for (var r = 0; r < 4; r++)
                                for (var c = 0; c < 4; c++)
                                  Positioned(
                                    left: gap + c * (cell + gap),
                                    top: gap + r * (cell + gap),
                                    width: cell,
                                    height: cell,
                                    child: _Tile(value: _game.grid[r][c]),
                                  ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '方向键 / 滑动 移动方块',
                      style: TextStyle(color: Color(0xFF776E65)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.gameOver});

  final int score;
  final bool gameOver;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFBBADA0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              const Text('得分', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (gameOver)
          const Text(
            '游戏结束',
            style: TextStyle(
              color: Color(0xFF776E65),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value});

  final int value;

  static const _colors = {
    0: Color(0xFFCDC1B4),
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
  };

  @override
  Widget build(BuildContext context) {
    final bg = _colors[value] ?? const Color(0xFF3C3A32);
    final darkText = value <= 4;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? null
          : Text(
              '$value',
              style: TextStyle(
                fontSize: value >= 1000 ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: darkText ? const Color(0xFF776E65) : Colors.white,
              ),
            ),
    );
  }
}
