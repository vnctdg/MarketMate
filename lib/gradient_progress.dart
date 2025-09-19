import 'dart:math';
import 'package:flutter/material.dart';

class GradientArcPainter extends CustomPainter {
  final double progress;
  final Color colorFrom;
  final Color colorTo;
  final double strokeWidth;
  final bool roundedCaps;

  GradientArcPainter({
    required this.progress,
    required this.colorFrom,
    required this.colorTo,
    this.strokeWidth = 10,
    this.roundedCaps = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final sweep = 2 * pi * (progress.clamp(0.0, 1.0));

    final shader = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + sweep,
      colors: [colorFrom, colorTo],
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = roundedCaps ? StrokeCap.round : StrokeCap.butt;

    canvas.drawArc(rect, -pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant GradientArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colorFrom != colorFrom || oldDelegate.colorTo != colorTo || oldDelegate.strokeWidth != strokeWidth;
  }
}