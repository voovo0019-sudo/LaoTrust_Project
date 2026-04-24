// =============================================================================
// v3.0: 메콩 파동 레이더 — LaoTrust 전용 듀얼 컬러 펄스 애니메이션
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';

const Color _royalBlue = Color(0xFF3B5BDB);
const Color _mekonGold = Color(0xFFF5B731);
const Color _royalNavy = Color(0xFF1E293B);

class RadarScanningWidget extends StatefulWidget {
  const RadarScanningWidget({
    super.key,
    this.size = 100,
    this.stageLabels = const [],
  });

  final double size;
  final List<String> stageLabels;

  @override
  State<RadarScanningWidget> createState() => _RadarScanningWidgetState();
}

class _RadarScanningWidgetState extends State<RadarScanningWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _pulseController3;
  late AnimationController _breathController;
  late AnimationController _sparkleController;

  final math.Random _random = math.Random();
  final List<_SparklePoint> _sparkles = [];

  @override
  void initState() {
    super.initState();

    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _pulseController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _sparkles.removeWhere((s) => s.age > 3);
            for (final s in _sparkles) {
              s.age++;
            }
          });
          Future.delayed(
            Duration(milliseconds: 300 + _random.nextInt(500)),
            () {
              if (mounted) {
                setState(() {
                  _sparkles.add(_SparklePoint(
                    angle: _random.nextDouble() * 2 * math.pi,
                    radiusFactor: 0.3 + _random.nextDouble() * 0.5,
                  ));
                });
                _sparkleController.forward(from: 0);
              }
            },
          );
        }
      });
    _sparkleController.forward();
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _pulseController3.dispose();
    _breathController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageLabels = widget.stageLabels.isEmpty
        ? const ['radar_stage_1km', 'radar_stage_3km', 'radar_stage_5km_plus']
        : widget.stageLabels;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController1,
            _pulseController2,
            _pulseController3,
            _breathController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _MekongPulsePainter(
                pulse1: _pulseController1.value,
                pulse2: _pulseController2.value,
                pulse3: _pulseController3.value,
                breath: _breathController.value,
                sparkles: List.from(_sparkles),
                royalBlue: _royalBlue,
                mekongGold: _mekonGold,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseController1,
          builder: (context, child) {
            final idx = (_pulseController1.value * stageLabels.length)
                .floor()
                .clamp(0, stageLabels.length - 1);
            return Column(
              children: [
                Text(
                  stageLabels[idx],
                  style: const TextStyle(
                    color: _royalNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n('radar_searching'),
                  style: TextStyle(
                    color: _royalBlue.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SparklePoint {
  _SparklePoint({required this.angle, required this.radiusFactor});
  final double angle;
  final double radiusFactor;
  int age = 0;
}

class _MekongPulsePainter extends CustomPainter {
  _MekongPulsePainter({
    required this.pulse1,
    required this.pulse2,
    required this.pulse3,
    required this.breath,
    required this.sparkles,
    required this.royalBlue,
    required this.mekongGold,
  });

  final double pulse1;
  final double pulse2;
  final double pulse3;
  final double breath;
  final List<_SparklePoint> sparkles;
  final Color royalBlue;
  final Color mekongGold;

  void _drawPulse(Canvas canvas, Offset center, double maxRadius,
      double progress, Color color, double maxOpacity) {
    final r = maxRadius * progress;
    final opacity = maxOpacity * (1.0 - progress);
    if (opacity <= 0 || r <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 8;

    // 배경 원
    final bgPaint = Paint()
      ..color = royalBlue.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    final borderPaint = Paint()
      ..color = royalBlue.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, maxRadius, borderPaint);

    // 내부 원 (고정)
    for (var i = 1; i <= 3; i++) {
      final r = maxRadius * (i / 3);
      final paint = Paint()
        ..color = royalBlue.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, r, paint);
    }

    // 메콩 파동 (골드 1차 - 빠름)
    _drawPulse(canvas, center, maxRadius, pulse1, mekongGold, 0.7);

    // 로얄블루 파동 (2차 - 중간)
    _drawPulse(canvas, center, maxRadius, pulse2, royalBlue, 0.5);

    // 골드 파동 (3차 - 느림, 거의 투명)
    _drawPulse(canvas, center, maxRadius, pulse3, mekongGold, 0.3);

    // 반짝임 포인트
    for (final sparkle in sparkles) {
      final opacity = (1.0 - sparkle.age / 4.0).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final r = maxRadius * sparkle.radiusFactor;
      final pos = Offset(
        center.dx + r * math.cos(sparkle.angle),
        center.dy + r * math.sin(sparkle.angle),
      );
      final sparklePaint = Paint()
        ..color = mekongGold.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 2.5, sparklePaint);
    }

    // 중앙 아이콘 (사람+별 — 숨쉬는 효과)
    final iconScale = 0.9 + 0.1 * breath;
    final iconRadius = 28.0 * iconScale;

    // 아이콘 배경 원 (골드 글로우)
    final glowPaint = Paint()
      ..color = mekongGold.withValues(alpha: 0.15 + 0.08 * breath)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, iconRadius + 6, glowPaint);

    // 아이콘 배경 원 (화이트)
    final iconBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, iconRadius, iconBgPaint);

    // 아이콘 테두리 (로얄블루)
    final iconBorderPaint = Paint()
      ..color = royalBlue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, iconRadius, iconBorderPaint);

    // 사람 아이콘 (머리)
    final headPaint = Paint()
      ..color = royalBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx, center.dy - 8 * iconScale),
      7 * iconScale,
      headPaint,
    );

    // 사람 아이콘 (몸통)
    final bodyPath = Path()
      ..moveTo(center.dx - 10 * iconScale, center.dy + 14 * iconScale)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 2 * iconScale,
        center.dx + 10 * iconScale,
        center.dy + 14 * iconScale,
      );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = royalBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // 별 (오른쪽 상단)
    _drawStar(
      canvas,
      Offset(center.dx + 14 * iconScale, center.dy - 16 * iconScale),
      7 * iconScale,
      mekongGold,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + 2 * math.pi / 10;
      final outerPoint = Offset(
        center.dx + radius * math.cos(outerAngle),
        center.dy + radius * math.sin(outerAngle),
      );
      final innerPoint = Offset(
        center.dx + (radius * 0.4) * math.cos(innerAngle),
        center.dy + (radius * 0.4) * math.sin(innerAngle),
      );
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MekongPulsePainter old) => true;
}
