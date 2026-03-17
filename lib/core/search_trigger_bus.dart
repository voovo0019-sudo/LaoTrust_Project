import 'package:flutter/foundation.dart';

/// v2.2: 레이더 수색 트리거 버스
/// - 홈 초기 진입에서는 절대 레이더를 돌리지 않는다.
/// - 신청 프로세스 최종 완료 시점에만 emit 한다.
class SearchTriggerBus {
  static final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _counter;

  static void trigger() {
    _counter.value = _counter.value + 1;
  }
}

