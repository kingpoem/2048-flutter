import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'evolution_theme.dart';

class CellFusionEffect extends StatefulWidget {
  const CellFusionEffect({super.key});

  @override
  State<CellFusionEffect> createState() => _CellFusionEffectState();
}

class _CellFusionEffectState extends State<CellFusionEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FusionPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _FusionPainter extends CustomPainter {
  _FusionPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.5;

    final membrane = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 0; i < 2; i++) {
      final offset = (progress * 0.55) * (i == 0 ? -1 : 1);
      final mergeT = Curves.easeInOut.transform(progress.clamp(0.0, 1.0));
      final cellCenter = Offset(center.dx + offset * radius * (1 - mergeT), center.dy);
      final cellRadius = radius * (0.42 - mergeT * 0.12);

      membrane.color = EvolutionTheme.mergeGlow.withValues(alpha: (1 - progress) * 0.8);
      canvas.drawCircle(cellCenter, cellRadius, membrane);

      final fill = Paint()
        ..color = EvolutionTheme.accent.withValues(alpha: (1 - progress) * 0.18);
      canvas.drawCircle(cellCenter, cellRadius * 0.82, fill);
    }

    final burstRadius = radius * (0.35 + progress * 0.75);
    final burst = Paint()
      ..color = EvolutionTheme.mergeGlow.withValues(alpha: (1 - progress) * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, burstRadius, burst);

    final particles = Paint()..color = EvolutionTheme.accentSoft.withValues(alpha: (1 - progress) * 0.9);
    for (var i = 0; i < 8; i++) {
      final angle = i / 8 * math.pi * 2;
      final dist = radius * (0.2 + progress * 0.55);
      final p = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      canvas.drawCircle(p, 2.2 * (1 - progress * 0.5), particles);
    }
  }

  @override
  bool shouldRepaint(covariant _FusionPainter oldDelegate) => oldDelegate.progress != progress;
}
