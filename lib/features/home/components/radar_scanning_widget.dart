// =============================================================================
// v1.3: 확대 수색 레이더 — 5km → 15km → 전역 시각적 스캐닝 애니메이션
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color _royalNavy = Color(0xFF1E293B);

class RadarScanningWidget extends StatefulWidget {
  const RadarScanningWidget({
    super.key,
    this.size = 120,
    this.label,
  });

  final double size;
  final String? label;

  @override
  State<RadarScanningWidget> createState() => _RadarScanningWidgetState();
}

class _RadarScanningWidgetState extends State<RadarScanningWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarSweepPainter(
                  progress: _controller.value,
                  color: _royalNavy,
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: TextStyle(
              color: _royalNavy.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  _RadarSweepPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    for (var i = 1; i <= 3; i++) {
      final r = radius * (i / 3);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.15 + 0.08 * (4 - i))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, r, paint);
    }

    final sweepAngle = 2 * math.pi * progress;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweepAngle,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      sweepAngle,
      true,
      sweepPaint,
    );

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(sweepAngle),
        center.dy + radius * math.sin(sweepAngle),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter old) =>
      old.progress != progress;
}
