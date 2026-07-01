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

  int _unseenApplicationCount = 0;
  int _applicationsLastSeenMs = 0;
  List<Map<String, dynamic>> _myApplicationsRaw = <Map<String, dynamic>>[];
  StreamSubscription<QuerySnapshot>? _myApplicationsSubscription;
  StreamSubscription<DocumentSnapshot>? _lastSeenSubscription;

  @override
  void initState() {
    super.initState();
    // Auth 상태 변화 감지 → 로그인 시 구독 시작, 로그아웃 시 구독 취소
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startBadgeSubscription(user.uid);
        _startApplicantBadgeSubscription(user.uid);
        _startUnseenApplicationSubscription(user.uid);
      } else {
        _cancelBadgeSubscription();
        _cancelApplicantBadgeSubscription();
        _cancelUnseenApplicationSubscription();
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

  void _startUnseenApplicationSubscription(String uid) {
    _myApplicationsSubscription?.cancel();
    _lastSeenSubscription?.cancel();

    _myApplicationsSubscription = FirebaseFirestore.instance
        .collection(kColApplications)
        .where(ApplicationFields.applicantId, isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      _myApplicationsRaw = snap.docs.map((doc) {
        final data = doc.data();
        final status = data[ApplicationFields.status]?.toString() ?? kAppStatusPending;
        final updatedRaw = data[ApplicationFields.statusUpdatedAt];
        final updatedMs = updatedRaw is Timestamp ? updatedRaw.millisecondsSinceEpoch : 0;
        return {'status': status, 'updatedMs': updatedMs};
      }).toList();
      _recomputeUnseenApplications();
    });

    _lastSeenSubscription = FirebaseFirestore.instance
        .collection(kColUsers)
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      final raw = data == null ? null : data[UserFields.applicationsLastSeenAt];
      _applicationsLastSeenMs = raw is Timestamp ? raw.millisecondsSinceEpoch : 0;
      _recomputeUnseenApplications();
    });
  }

  void _recomputeUnseenApplications() {
    var count = 0;
    for (final app in _myApplicationsRaw) {
      final status = app['status']?.toString() ?? kAppStatusPending;
      final updatedMs = app['updatedMs'] as int? ?? 0;
      final isDecided = status == kAppStatusAccepted || status == kAppStatusRejected;
      if (isDecided && updatedMs > _applicationsLastSeenMs) {
        count++;
      }
    }
    if (!mounted) return;
    setState(() => _unseenApplicationCount = count);
  }

  void _cancelUnseenApplicationSubscription() {
    _myApplicationsSubscription?.cancel();
    _myApplicationsSubscription = null;
    _lastSeenSubscription?.cancel();
    _lastSeenSubscription = null;
    _myApplicationsRaw = <Map<String, dynamic>>[];
    _applicationsLastSeenMs = 0;
    if (mounted) setState(() => _unseenApplicationCount = 0);
  }

  @override
  void dispose() {
    _myApplicationsSubscription?.cancel();
    _lastSeenSubscription?.cancel();
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
            unseenApplicationCount: _unseenApplicationCount,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onIndexChanged: (index) =>
            ref.read(currentTabProvider.notifier).setTab(index),
        profileBadgeCount: _acceptedCount + _pendingApplicantCount + _unseenApplicationCount,
      ),
    );
  }
}
