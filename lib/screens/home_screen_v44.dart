import 'package:flutter/material.dart';
import 'package:lao_trust/features/screens/home_screen.dart' as home_current;

/// Deprecated legacy home screen (v44).
/// Kept only for import compatibility; use `vCurrent.HomeScreen` instead.
class HomeScreenV44 extends StatelessWidget {
  const HomeScreenV44({super.key});

  @override
  Widget build(BuildContext context) {
    return const home_current.HomeScreen();
  }
}

