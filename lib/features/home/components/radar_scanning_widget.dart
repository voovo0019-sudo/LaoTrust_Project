// =============================================================================
// LaoTrust — 메콩 소나 레이더 v5.0
// Flutter Icon 기반 아이콘 + 완료 UX 추가
// =============================================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';

const Color _royalBlue = Color(0xFF3B5BDB);
const Color _mekongGold = Color(0xFFF5B731);
const Color _royalNavy = Color(0xFF1E293B);

class RadarScanningWidget extends StatefulWidget {
  const RadarScanningWidget({
    super.key,
    this.size = 280,
    this.stageLabels = const [],
    this.isComplete = false,
  });

  final double size;
  final List<String> stageLabels;
  final bool isComplete;

  @override
  State<RadarScanningWidget> createState() => _RadarScanningWidgetState();
}

class _RadarScanningWidgetState extends State<RadarScanningWidget>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _breathController;
  late AnimationController _pin1Controller;
  late AnimationController _pin2Controller;
  late AnimationController _pin3Controller;
  late AnimationController _stageController;
  late AnimationController _completeController;

  static const List<_PinData> _pins = [
    _PinData(angle: 0.8, radiusFactor: 0.35),
    _PinData(angle: 2.5, radiusFactor: 0.62),
    _PinData(angle: 4.2, radiusFactor: 0.82),
  ];

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pin1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _pin1Controller.forward();
    });

    _pin2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _pin2Controller.forward();
    });

    _pin3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) _pin3Controller.forward();
    });

    _stageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _completeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(RadarScanningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isComplete && !oldWidget.isComplete) {
      _scanController.stop();
      _completeController.forward();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _breathController.dispose();
    _pin1Controller.dispose();
    _pin2Controller.dispose();
    _pin3Controller.dispose();
    _stageController.dispose();
    _completeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageLabels = widget.stageLabels.isEmpty
        ? const ['1km', '3km', '5km+']
        : widget.stageLabels;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ━━━ 레이더 원 + 아이콘 스택 ━━━
        AnimatedBuilder(
          animation: Listenable.merge([
            _scanController,
            _breathController,
            _pin1Controller,
            _pin2Controller,
            _pin3Controller,
            _completeController,
          ]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 소나 배경
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _SonarPainter(
                    scanAngle: _scanController.value * 2 * math.pi,
                    breath: _breathController.value,
                    pin1Progress: _pin1Controller.value,
                    pin2Progress: _pin2Controller.value,
                    pin3Progress: _pin3Controller.value,
                    pins: _pins,
                    royalBlue: _royalBlue,
                    mekongGold: _mekongGold,
                    isComplete: widget.isComplete,
                    completeProgress: _completeController.value,
                  ),
                ),
                // 핀 위에 Flutter Icon 오버레이
                ..._buildPinIcons(),
                // 중앙 아이콘
                _buildCenterIcon(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        // ━━━ 하단 텍스트 ━━━
        widget.isComplete
            ? _buildCompleteText(context)
            : _buildSearchingText(context, stageLabels),
      ],
    );
  }

  // 중앙 아이콘 (Flutter Icon)
  Widget _buildCenterIcon() {
    final breath = _breathController.value;
    final scale = 0.92 + 0.08 * breath;
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _mekongGold.withValues(alpha: 0.3 + 0.2 * breath),
                  blurRadius: 16 + 8 * breath,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: _royalBlue.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: widget.isComplete
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: _royalBlue,
                    size: 36,
                  )
                : const Icon(
                    Icons.location_searching_rounded,
                    color: _royalBlue,
                    size: 32,
                  ),
          ),
        );
      },
    );
  }

  // 핀 아이콘들 (Flutter Icon)
  List<Widget> _buildPinIcons() {
    final pinProgresses = [
      _pin1Controller.value,
      _pin2Controller.value,
      _pin3Controller.value,
    ];
    final halfSize = widget.size / 2;
    final maxRadius = halfSize - 8;

    return List.generate(_pins.length, (i) {
      final progress = pinProgresses[i];
      if (progress <= 0) return const SizedBox.shrink();
      final pin = _pins[i];
      final r = maxRadius * pin.radiusFactor;
      final scale = Curves.elasticOut.transform(progress.clamp(0.0, 1.0));
      final dx = r * math.cos(pin.angle);
      final dy = r * math.sin(pin.angle);

      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _royalBlue.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _mekongGold.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle_rounded,
              color: _royalBlue,
              size: 20,
            ),
          ),
        ),
      );
    });
  }

  // 수색 중 텍스트
  Widget _buildSearchingText(BuildContext context, List<String> stageLabels) {
    return AnimatedBuilder(
      animation: _stageController,
      builder: (context, child) {
        final progress = _stageController.value;
        final int idx;
        if (progress < 0.33) {
          idx = 0;
        } else if (progress < 0.66) {
          idx = 1;
        } else {
          idx = 2;
        }
        final label = stageLabels[idx.clamp(0, stageLabels.length - 1)];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Column(
            key: ValueKey(idx),
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _royalNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n('radar_searching'),
                style: TextStyle(
                  color: _royalBlue.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // 완료 텍스트
  Widget _buildCompleteText(BuildContext context) {
    return AnimatedBuilder(
      animation: _completeController,
      builder: (context, child) {
        return Opacity(
          opacity: _completeController.value,
          child: Column(
            children: [
              Text(
                context.l10n('radar_complete_delivered'),
                style: const TextStyle(
                  color: _royalBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n('radar_expert_contact_soon'),
                style: TextStyle(
                  color: _royalNavy.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinData {
  const _PinData({required this.angle, required this.radiusFactor});
  final double angle;
  final double radiusFactor;
}

class _SonarPainter extends CustomPainter {
  _SonarPainter({
    required this.scanAngle,
    required this.breath,
    required this.pin1Progress,
    required this.pin2Progress,
    required this.pin3Progress,
    required this.pins,
    required this.royalBlue,
    required this.mekongGold,
    required this.isComplete,
    required this.completeProgress,
  });

  final double scanAngle;
  final double breath;
  final double pin1Progress;
  final double pin2Progress;
  final double pin3Progress;
  final List<_PinData> pins;
  final Color royalBlue;
  final Color mekongGold;
  final bool isComplete;
  final double completeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 8;

    // 배경 원
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..color = royalBlue.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..color = royalBlue.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 동심원 3개
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        maxRadius * (i / 3),
        Paint()
          ..color = royalBlue.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 십자선
    final crossPaint = Paint()
      ..color = royalBlue.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crossPaint,
    );

    if (!isComplete) {
      // 소나 잔상 부채꼴
      const sweepAngle = math.pi / 2;
      final trailPaint = Paint()..style = PaintingStyle.fill;
      const steps = 20;
      for (var i = 0; i < steps; i++) {
        final ratio = i / steps;
        final alpha = (0.18 * ratio).clamp(0.0, 1.0);
        trailPaint.color = mekongGold.withValues(alpha: alpha);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: maxRadius - 2),
          scanAngle - sweepAngle * ratio,
          sweepAngle / steps,
          true,
          trailPaint,
        );
      }

      // 소나 스캔 라인
      canvas.drawLine(
        center,
        Offset(
          center.dx + maxRadius * math.cos(scanAngle),
          center.dy + maxRadius * math.sin(scanAngle),
        ),
        Paint()
          ..color = mekongGold.withValues(alpha: 0.9)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // 완료 시 골드 파동
    if (isComplete && completeProgress > 0) {
      for (var i = 0; i < 3; i++) {
        final delay = i * 0.25;
        final p = (completeProgress - delay).clamp(0.0, 1.0);
        if (p <= 0) continue;
        canvas.drawCircle(
          center,
          maxRadius * p * 0.8,
          Paint()
            ..color = mekongGold.withValues(alpha: (1 - p) * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SonarPainter old) => true;
}
