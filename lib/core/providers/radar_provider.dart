// =============================================================================
// LaoTrust — RadarProvider
// SearchTriggerBus를 대체하는 Riverpod 기반 레이더 트리거
// =============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RadarNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state = state + 1;
}

final radarProvider = NotifierProvider<RadarNotifier, int>(
  RadarNotifier.new,
);
