import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabNotifier extends StateNotifier<int> {
  TabNotifier() : super(0);
  void setTab(int index) => state = index;
  void goHome() => state = 0;
}

final currentTabProvider = StateNotifierProvider<TabNotifier, int>(
  (ref) => TabNotifier(),
);
