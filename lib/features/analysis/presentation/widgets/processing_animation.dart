import 'dart:math';
import 'package:flutter/material.dart';

class ProcessingAnimation extends StatefulWidget {
  const ProcessingAnimation({super.key});

  @override
  State<ProcessingAnimation> createState() => _ProcessingAnimationState();
}

class _ProcessingAnimationState extends State<ProcessingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      builder: (_, __) {
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _DotGridPainter(_controller.value),
          ),
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final double progress;
  _DotGridPainter(this.progress);

  static const _rows = 3;
  static const _cols = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _cols;
    final cellH = size.height / _rows;
    final paint = Paint();

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final index = r * _cols + c;
        final phase = (progress - index * 0.1) % 1.0;
        final pulse = (sin(phase * pi * 2) + 1) / 2;

        final cx = cellW * c + cellW / 2;
        final cy = cellH * r + cellH / 2;

        paint.color = Color.lerp(
          Colors.white24,
          Colors.white,
          pulse,
        )!;
        canvas.drawCircle(Offset(cx, cy), 14, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.progress != progress;
}
