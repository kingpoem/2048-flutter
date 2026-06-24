import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ai2048.dart';
import '../game/game2048.dart';
import 'cell_fusion_effect.dart';
import 'evolution_theme.dart';
import 'evolution_tile.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();
  late Game2048 _game;
  Set<(int, int)> _mergingCells = {};
  (int, int)? _spawningCell;
  bool _aiRunning = false;
  bool _aiThinking = false;

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

  void _applyMove(Direction direction) {
    final moved = _game.move(direction);
    if (!moved) return;

    setState(() {
      _mergingCells = _game.lastMergedAt.toSet();
      _spawningCell = _game.lastSpawnedAt;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _mergingCells = {};
        _spawningCell = null;
      });
    });
  }

  void _newGame() {
    _aiRunning = false;
    setState(() {
      _game.reset();
      _mergingCells = {};
      _spawningCell = null;
      _aiThinking = false;
    });
  }

  void _toggleAi() {
    if (_aiRunning) {
      setState(() => _aiRunning = false);
      return;
    }
    if (_game.gameOver) return;
    setState(() => _aiRunning = true);
    _runAiStep();
  }

  Future<void> _runAiStep() async {
    if (!_aiRunning || _game.gameOver || !mounted) {
      if (mounted) setState(() => _aiRunning = false);
      return;
    }

    setState(() => _aiThinking = true);
    final grid = [for (final row in _game.grid) List<int>.from(row)];
    final direction = await compute(findBestDirectionForGrid, grid);
    if (!mounted || !_aiRunning) return;

    setState(() => _aiThinking = false);
    if (direction == null) {
      setState(() => _aiRunning = false);
      return;
    }

    _applyMove(direction);
    if (!_aiRunning || _game.gameOver) return;

    await Future.delayed(const Duration(milliseconds: 180));
    if (mounted && _aiRunning) _runAiStep();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _applyMove(Direction.up);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _applyMove(Direction.down);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _applyMove(Direction.left);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _applyMove(Direction.right);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  int get _highestValue {
    var max = 0;
    for (final row in _game.grid) {
      for (final value in row) {
        if (value > max) max = value;
      }
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    final highest = _highestValue;
    final currentStage = EvolutionTheme.stageFor(highest);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07140F),
              EvolutionTheme.background,
              Color(0xFF102820),
            ],
          ),
        ),
        child: SafeArea(
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              onVerticalDragEnd: (details) {
                final dy = details.primaryVelocity ?? 0;
                if (dy.abs() < 100) return;
                _applyMove(dy < 0 ? Direction.up : Direction.down);
              },
              onHorizontalDragEnd: (details) {
                final dx = details.primaryVelocity ?? 0;
                if (dx.abs() < 100) return;
                _applyMove(dx < 0 ? Direction.left : Direction.right);
              },
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        _Header(
                          onNewGame: _newGame,
                          aiRunning: _aiRunning,
                          aiThinking: _aiThinking,
                          onToggleAi: _toggleAi,
                        ),
                        const SizedBox(height: 18),
                        _ScorePanel(
                          score: _game.score,
                          stageName: highest > 0 ? currentStage.name : '培养皿',
                          stageSubtitle: highest > 0 ? currentStage.subtitle : '等待生命诞生',
                          gameOver: _game.gameOver,
                        ),
                        const SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 10.0;
                              final cell = (constraints.maxWidth - gap * 5) / 4;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const RadialGradient(
                                        colors: [Color(0xFF1B4D38), EvolutionTheme.board],
                                        radius: 1.1,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: EvolutionTheme.boardBorder, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: EvolutionTheme.accent.withValues(alpha: 0.08),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (var r = 0; r < 4; r++)
                                    for (var c = 0; c < 4; c++)
                                      Positioned(
                                        left: gap + c * (cell + gap),
                                        top: gap + r * (cell + gap),
                                        width: cell,
                                        height: cell,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            EvolutionTile(
                                              value: _game.grid[r][c],
                                              isMerging: _mergingCells.contains((r, c)),
                                              isSpawning: _spawningCell == (r, c),
                                            ),
                                            if (_mergingCells.contains((r, c)))
                                              Positioned.fill(
                                                child: CellFusionEffect(
                                                  key: ValueKey('fusion-$r-$c-${_game.score}'),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _game.gameOver ? '进化停滞 — 细胞无法继续融合' : '滑动或方向键移动 · 相同生物融合进化',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: EvolutionTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onNewGame,
    required this.aiRunning,
    required this.aiThinking,
    required this.onToggleAi,
  });

  final VoidCallback onNewGame;
  final bool aiRunning;
  final bool aiThinking;
  final VoidCallback onToggleAi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [EvolutionTheme.accent, Color(0xFFB2FFDA)],
              ).createShader(bounds),
              child: const Text(
                '进化 2048',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Text(
              '从单细胞到智慧生命',
              style: TextStyle(color: EvolutionTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: onToggleAi,
          style: FilledButton.styleFrom(
            backgroundColor: aiRunning
                ? const Color(0xFF5C2E2E)
                : EvolutionTheme.accent.withValues(alpha: 0.18),
            foregroundColor: aiRunning ? const Color(0xFFFFAB91) : EvolutionTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: Icon(
            aiThinking ? Icons.hourglass_top_rounded : Icons.smart_toy_rounded,
            size: 18,
          ),
          label: Text(aiRunning ? '停止 AI' : 'AI 托管'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onNewGame,
          style: FilledButton.styleFrom(
            backgroundColor: EvolutionTheme.accentSoft,
            foregroundColor: EvolutionTheme.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.biotech_rounded, size: 18),
          label: const Text('新培养皿'),
        ),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.score,
    required this.stageName,
    required this.stageSubtitle,
    required this.gameOver,
  });

  final int score;
  final String stageName;
  final String stageSubtitle;
  final bool gameOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _MetricCard(label: '进化度', value: '$score'),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              label: '当前物种',
              value: stageName,
              subtitle: stageSubtitle,
            ),
          ),
          if (gameOver)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF5C2E2E).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF8A80).withValues(alpha: 0.35)),
              ),
              child: const Text(
                '灭绝',
                style: TextStyle(
                  color: Color(0xFFFFAB91),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EvolutionTheme.board,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvolutionTheme.boardBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: EvolutionTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: EvolutionTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: EvolutionTheme.textMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
