// =============================================================================
// LT-10 MainTabScreen v2.1 - 프로필 탭 배지 추가
// =============================================================================
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../home/components/custom_bottom_nav.dart';
import '../../core/providers/providers.dart';
import '../../data/firestore_schema.dart';
import '../../firebase_options.dart';

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({super.key});
  static const String routeName = '/main';
  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  StreamSubscription<QuerySnapshot>? _badgeSubscription;
  StreamSubscription<User?>? _authSubscription;
  int _acceptedCount = 0;
  int _pendingApplicantCount = 0;
  StreamSubscription<QuerySnapshot>? _applicantBadgeSubscription;

  @override
  void initState() {
    super.initState();
    // Auth 상태 변화 감지 → 로그인 시 구독 시작, 로그아웃 시 구독 취소
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startBadgeSubscription(user.uid);
        _startApplicantBadgeSubscription(user.uid);
      } else {
        _cancelBadgeSubscription();
        _cancelApplicantBadgeSubscription();
      }
    });
  }

  void _startBadgeSubscription(String uid) {
    _badgeSubscription?.cancel();
    _badgeSubscription = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(DefaultFirebaseOptions.currentPlatform.projectId)
        .collection('public')
        .doc('data')
        .collection('requests')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _acceptedCount = snap.docs.length;
      });
    });
  }

  void _cancelBadgeSubscription() {
    _badgeSubscription?.cancel();
    _badgeSubscription = null;
    if (mounted) setState(() => _acceptedCount = 0);
  }

  void _startApplicantBadgeSubscription(String uid) {
    _applicantBadgeSubscription?.cancel();
    _applicantBadgeSubscription = FirebaseFirestore.instance
        .collection(kColApplications)
        .where(ApplicationFields.employerId, isEqualTo: uid)
        .where(ApplicationFields.status, isEqualTo: kAppStatusPending)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _pendingApplicantCount = snap.docs.length;
      });
    });
  }

  void _cancelApplicantBadgeSubscription() {
    _applicantBadgeSubscription?.cancel();
    _applicantBadgeSubscription = null;
    if (mounted) setState(() => _pendingApplicantCount = 0);
  }

  @override
  void dispose() {
    _applicantBadgeSubscription?.cancel();
    _badgeSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final currentIndex = ref.watch(currentTabProvider);
    // ignore: unused_local_variable
    final _ = themeMode;
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeScreen(
            locale: locale,
            onLocaleChanged: (l) =>
                ref.read(localeProvider.notifier).setLocale(l),
          ),
          const JobsScreen(),
          const ChatScreen(),
          ProfileScreen(
            acceptedCount: _acceptedCount,
            pendingApplicantCount: _pendingApplicantCount,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onIndexChanged: (index) =>
            ref.read(currentTabProvider.notifier).setTab(index),
        profileBadgeCount: _acceptedCount,
      ),
    );
  }
}
