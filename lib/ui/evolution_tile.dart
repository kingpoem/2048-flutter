import 'package:flutter/material.dart';

import 'evolution_creature_painter.dart';
import 'evolution_theme.dart';

class EvolutionTile extends StatefulWidget {
  const EvolutionTile({
    super.key,
    required this.value,
    required this.isMerging,
    required this.isSpawning,
  });

  final int value;
  final bool isMerging;
  final bool isSpawning;

  @override
  State<EvolutionTile> createState() => _EvolutionTileState();
}

class _EvolutionTileState extends State<EvolutionTile> with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _eventController;
  late final Animation<double> _eventScale;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _eventController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _eventScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _eventController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant EvolutionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMerging || widget.isSpawning) {
      _eventController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value == 0) {
      return Container(
        decoration: BoxDecoration(
          color: EvolutionTheme.emptyCell,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
      );
    }

    final stage = EvolutionTheme.stageFor(widget.value);
    final bg = EvolutionTheme.tileColor(widget.value);

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _eventController]),
      builder: (context, child) {
        final pulse = _idleController.value;
        final scale = widget.isMerging || widget.isSpawning ? _eventScale.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  bg.withValues(alpha: 0.95),
                  bg.withValues(alpha: 0.72),
                ],
                center: const Alignment(-0.2, -0.25),
                radius: 1.1,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: EvolutionTheme.creatureColor(widget.value).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: widget.isMerging
                  ? [
                      BoxShadow(
                        color: EvolutionTheme.mergeGlow.withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: EvolutionCreaturePainter(
                      value: widget.value,
                      pulse: pulse,
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stage.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: EvolutionTheme.textPrimary.withValues(alpha: 0.95),
                            fontSize: widget.value >= 1024 ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '${widget.value}',
                          style: TextStyle(
                            color: EvolutionTheme.textPrimary.withValues(alpha: 0.75),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
