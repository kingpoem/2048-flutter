import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'evolution_theme.dart';

class EvolutionCreaturePainter extends CustomPainter {
  EvolutionCreaturePainter({
    required this.value,
    required this.pulse,
  });

  final int value;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (value == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.shortestSide * (0.34 + pulse * 0.04);
    final color = EvolutionTheme.creatureColor(value);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    switch (value) {
      case 2:
        _drawBacterium(canvas, scale, color);
      case 4:
        _drawAmoeba(canvas, scale, color);
      case 8:
        _drawAlgae(canvas, scale, color);
      case 16:
        _drawParamecium(canvas, scale, color);
      case 32:
        _drawJellyfish(canvas, scale, color);
      case 64:
        _drawWorm(canvas, scale, color);
      case 128:
        _drawFish(canvas, scale, color);
      case 256:
        _drawFrog(canvas, scale, color);
      case 512:
        _drawReptile(canvas, scale, color);
      case 1024:
        _drawBird(canvas, scale, color);
      case 2048:
        _drawMammal(canvas, scale, color);
      default:
        _drawMammal(canvas, scale, color);
    }

    canvas.restore();
  }

  void _drawBacterium(Canvas canvas, double scale, Color color) {
    final body = Paint()..color = color;
    canvas.drawCircle(Offset.zero, scale, body);
    final ring = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.12;
    canvas.drawCircle(Offset.zero, scale * 0.72, ring);
    final flagella = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = scale * 0.08
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.45;
      canvas.drawLine(
        Offset(math.cos(angle) * scale, math.sin(angle) * scale),
        Offset(math.cos(angle) * scale * 1.55, math.sin(angle) * scale * 1.55),
        flagella,
      );
    }
  }

  void _drawAmoeba(Canvas canvas, double scale, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i / 8 * math.pi * 2;
      final wobble = 1 + math.sin(angle * 3 + pulse * math.pi * 2) * 0.12;
      final r = scale * wobble * (i.isEven ? 1.05 : 0.92);
      final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(-scale * 0.25, -scale * 0.15),
      scale * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _drawAlgae(Canvas canvas, double scale, Color color) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: scale * 1.5, height: scale * 1.1),
      Radius.circular(scale),
    );
    canvas.drawRRect(body, Paint()..color = color);
    final chloroplast = Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.7);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-scale * 0.2, 0), width: scale * 0.35, height: scale * 0.55),
      chloroplast,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(scale * 0.25, scale * 0.1), width: scale * 0.3, height: scale * 0.45),
      chloroplast,
    );
  }

  void _drawParamecium(Canvas canvas, double scale, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: scale * 1.8, height: scale * 1.1),
      Paint()..color = color,
    );
    final cilia = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = scale * 0.05;
    for (var i = 0; i < 12; i++) {
      final t = i / 11;
      final x = -scale * 0.9 + t * scale * 1.8;
      canvas.drawLine(Offset(x, -scale * 0.65), Offset(x, -scale * 0.9), cilia);
      canvas.drawLine(Offset(x, scale * 0.65), Offset(x, scale * 0.9), cilia);
    }
    canvas.drawCircle(
      Offset(scale * 0.15, 0),
      scale * 0.12,
      Paint()..color = const Color(0xFF1565C0).withValues(alpha: 0.8),
    );
  }

  void _drawJellyfish(Canvas canvas, double scale, Color color) {
    final dome = Path()
      ..moveTo(-scale * 0.9, scale * 0.1)
      ..quadraticBezierTo(0, -scale * 1.1, scale * 0.9, scale * 0.1)
      ..lineTo(-scale * 0.9, scale * 0.1);
    canvas.drawPath(dome, Paint()..color = color);
    final tentacles = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = scale * 0.07
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      final x = i * scale * 0.28;
      canvas.drawLine(
        Offset(x, scale * 0.1),
        Offset(x + math.sin(pulse * math.pi * 2 + i) * scale * 0.15, scale * 1.0),
        tentacles,
      );
    }
  }

  void _drawWorm(Canvas canvas, double scale, Color color) {
    final path = Path();
    for (var i = 0; i <= 20; i++) {
      final t = i / 20;
      final x = -scale + t * scale * 2;
      final y = math.sin(t * math.pi * 2 + pulse * math.pi) * scale * 0.25;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.35
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
    canvas.drawCircle(Offset(-scale, 0), scale * 0.18, Paint()..color = color);
  }

  void _drawFish(Canvas canvas, double scale, Color color) {
    final body = Path()
      ..moveTo(-scale * 0.8, 0)
      ..quadraticBezierTo(0, -scale * 0.7, scale * 0.9, 0)
      ..quadraticBezierTo(0, scale * 0.7, -scale * 0.8, 0);
    canvas.drawPath(body, Paint()..color = color);
    final tail = Path()
      ..moveTo(-scale * 0.8, 0)
      ..lineTo(-scale * 1.2, -scale * 0.35)
      ..lineTo(-scale * 1.2, scale * 0.35)
      ..close();
    canvas.drawPath(tail, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawCircle(
      Offset(scale * 0.35, -scale * 0.12),
      scale * 0.08,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
  }

  void _drawFrog(Canvas canvas, double scale, Color color) {
    canvas.drawCircle(Offset(-scale * 0.35, -scale * 0.15), scale * 0.42, Paint()..color = color);
    canvas.drawCircle(Offset(scale * 0.35, -scale * 0.15), scale * 0.42, Paint()..color = color);
    canvas.drawCircle(Offset(0, scale * 0.25), scale * 0.55, Paint()..color = color);
    canvas.drawCircle(Offset(-scale * 0.45, -scale * 0.45), scale * 0.16, Paint()..color = color.withValues(alpha: 0.9));
    canvas.drawCircle(Offset(scale * 0.45, -scale * 0.45), scale * 0.16, Paint()..color = color.withValues(alpha: 0.9));
    canvas.drawCircle(
      Offset(-scale * 0.45, -scale * 0.45),
      scale * 0.07,
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      Offset(scale * 0.45, -scale * 0.45),
      scale * 0.07,
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );
  }

  void _drawReptile(Canvas canvas, double scale, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, scale * 0.1), width: scale * 1.7, height: scale * 0.55),
        const Radius.circular(8),
      ),
      Paint()..color = color,
    );
    canvas.drawCircle(Offset(scale * 0.75, -scale * 0.05), scale * 0.28, Paint()..color = color);
    final leg = Paint()..color = color.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(-scale * 0.45, scale * 0.35), scale * 0.12, leg);
    canvas.drawCircle(Offset(scale * 0.2, scale * 0.35), scale * 0.12, leg);
    canvas.drawCircle(Offset(scale * 0.55, scale * 0.35), scale * 0.12, leg);
  }

  void _drawBird(Canvas canvas, double scale, Color color) {
    final wingAngle = math.sin(pulse * math.pi * 2) * 0.25;
    canvas.save();
    canvas.rotate(-wingAngle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-scale * 0.15, -scale * 0.2), width: scale * 0.9, height: scale * 0.35),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    canvas.restore();
    canvas.save();
    canvas.rotate(wingAngle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-scale * 0.15, scale * 0.2), width: scale * 0.9, height: scale * 0.35),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(center: Offset(scale * 0.1, 0), width: scale * 1.1, height: scale * 0.65),
      Paint()..color = color,
    );
    final beak = Path()
      ..moveTo(scale * 0.65, 0)
      ..lineTo(scale * 0.95, -scale * 0.05)
      ..lineTo(scale * 0.65, scale * 0.1)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFFB74D));
  }

  void _drawMammal(Canvas canvas, double scale, Color color) {
    canvas.drawCircle(Offset(0, scale * 0.1), scale * 0.55, Paint()..color = color);
    canvas.drawCircle(Offset(-scale * 0.42, -scale * 0.35), scale * 0.22, Paint()..color = color);
    canvas.drawCircle(Offset(scale * 0.42, -scale * 0.35), scale * 0.22, Paint()..color = color);
    canvas.drawCircle(Offset(-scale * 0.15, -scale * 0.05), scale * 0.07, Paint()..color = Colors.black54);
    canvas.drawCircle(Offset(scale * 0.15, -scale * 0.05), scale * 0.07, Paint()..color = Colors.black54);
    canvas.drawCircle(Offset(0, scale * 0.12), scale * 0.06, Paint()..color = const Color(0xFF8D6E63));
  }

  @override
  bool shouldRepaint(covariant EvolutionCreaturePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.pulse != pulse;
  }
}
