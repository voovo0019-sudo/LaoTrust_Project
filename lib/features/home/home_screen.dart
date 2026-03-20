// =============================================================================
// v7.5 메인 대시보드 진입점 (Main Entry)
//
// app.dart → MaterialApp(home: MainTabScreen) → MainTabScreen이 본 파일을 import.
//
// 급구 알바 실시간 동기화:
//   아래 export되는 [HomeScreen] 본문(`screens/home_screen.dart`)이
//   [QuickJobsSection](components/quick_jobs.dart)을 포함하며,
//   FirebaseService.getQuickJobs()의 Firestore snapshots() 스트림으로 리스트가 갱신된다.
//
// 알바 등록 버튼(프리미엄 카드) 로그인 제어:
//   QuickJobsSection 내부 `_buildPremiumPostCard`에서 Firebase 활성 시 비로그인이면
//   로그인 안내 다이얼로그 후 프로필로 유도한다. (v7.5)
//
// 구현 중복을 피하기 위해 실제 위젯 트리는 `../screens/home_screen.dart`에 두고 export만 한다.
// =============================================================================

export '../screens/home_screen.dart';
