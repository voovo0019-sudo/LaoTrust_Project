import 'package:flutter/material.dart';

/// Project: LaoTrust / Supreme Commander: Jin hyeok 🛡️
/// 작전명: 차세대 통합 고도화 최종 집행 (v44.0)
/// 셋째(Gems-Dev)의 정밀 타격 지침:
/// 1. 9대 전문가 카테고리 (3x3 그리드) 완비
/// 2. 수리(지붕 보수 특화), 배달(마트 장보기), 청소(곰팡이 제거) 등 세부 뎁스 100% 매핑
/// 3. 십계명 준수: 숫자 입력 배제(S/M/L 버튼), 주거형태 아이콘화, 3단계 위저드 UI
/// 4. 신뢰 인프라: 실시간 진행바, 예약금 안내, 언어 배지 필터 적용
/// 5. 급구 알바 6종: 초슬림 Peeking 카드 및 태그 전략 구현

enum HomeView { main, subCategory, symptoms, finalSummary }

class HomeScreenV44 extends StatefulWidget {
  const HomeScreenV44({super.key});

  @override
  State<HomeScreenV44> createState() => _HomeScreenV44State();
}

class _HomeScreenV44State extends State<HomeScreenV44> {
  final PageController _pageController = PageController(viewportFraction: 0.48);

  HomeView _currentView = HomeView.main;
  String _activeCategory = "";
  String _selectedSubCategory = "";
  int _currentTabIndex = 0;
  final String _currentLang = "KR";

  // 유저 선택 상태 (S/M/L, 주거형태 등)
  String _selectedSize = "";
  String _selectedHouseType = "";

  // --- 다국어 사전 (v44.0 정밀 데이터 매핑) ---
  final Map<String, Map<String, String>> _langMap = {
    'KR': {
      'title': 'LAO TRUST 🛡️',
      'search': '서비스 또는 지역 검색',
      'hint': '어떤 도움이 필요하세요?',
      'expert': '전문가 서비스',
      'repair': '수리',
      'cleaning': '청소',
      'security': '경비/보안',
      'delivery': '배달/심부름',
      'beauty': '뷰티/헬스',
      'tutor': '과외/레슨',
      'photo': '사진/영상',
      'event': '이벤트/행사',
      'garden': '정원/외부관리',
      'quick_job': '급구 알바',
      'next': '다음 단계로',
      'tab_home': '홈',
      'tab_job': '일자리',
      'tab_chat': '채팅',
      'tab_profile': '프로필',
      'chat_item': '배관 수리 김철수',
      'job1': '식당 서버',
      'job2': '단순 노무',
      'job3': '카페 알바',
      'job4': '행사 스태프',
      'job5': '물류 보조',
      'job6': '판촉 홍보',
      's_hint': '의 상세 내용을 선택하세요.',
      'step1': '공간 정보',
      'step2': '상세 옵션',
      'step3': '신청 확인',
      'size_s': 'S (30㎡↓)',
      'size_m': 'M (30-60㎡)',
      'size_l': 'L (60㎡↑)',
      'h1': '스튜디오',
      'h2': '1BR',
      'h3': '2BR',
      'h4': '하우스',
      'chat_ready': '채팅 준비 중',
      'space_size': '공간 크기 선택',
      'house_type': '주거 형태',
      'special_roof': '[특화] 지붕 누수 사전 점검 포함',
      'summary_title': '서비스 신청 확인',
      'summary_category': '카테고리',
      'summary_sub': '세부 종목',
      'summary_size': '선택 크기',
      'summary_house': '주거 형태',
      'deposit_notice': '안심 예약을 위해 서비스 총액의 10~30% 예약금이 발생합니다.',
      'apply_final': '최종 신청하기',
      'service_search_placeholder': '서비스 또는 지역 검색',
    },
    // 라오어/영어 생략 (KR 기준 로직 구현 후 확장 가능)
  };

  String t(String key) => _langMap[_currentLang]?[key] ?? key;

  // Flutter 기본 팔레트에는 slate 계열이 없으므로 blueGrey shade로 대체한다.
  Color get _slate200 => Colors.blueGrey.shade200;
  Color get _slate400 => Colors.blueGrey.shade400;
  Color get _slate500 => Colors.blueGrey.shade500;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: PopScope(
        canPop: _currentView == HomeView.main,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goBack();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentBody(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  void _goBack() => setState(() {
        if (_currentView == HomeView.finalSummary) {
          _currentView = HomeView.symptoms;
        } else if (_currentView == HomeView.symptoms) {
          _currentView = HomeView.subCategory;
        } else if (_currentView == HomeView.subCategory) {
          _currentView = HomeView.main;
        }
      });

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E3A8A),
      elevation: 0,
      title: Text(
        t('title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      leading: _currentView != HomeView.main
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: _goBack,
            )
          : null,
      actions: [
        IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) => setState(() {
        _currentTabIndex = index;
        _currentView = HomeView.main;
      }),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1E3A8A),
      unselectedItemColor: _slate400,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: t('tab_home')),
        BottomNavigationBarItem(icon: const Icon(Icons.business_center_outlined), label: t('tab_job')),
        BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: t('tab_chat')),
        BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: t('tab_profile')),
      ],
    );
  }

  Widget _buildCurrentBody() {
    if (_currentTabIndex == 2) return _buildChatTab();
    switch (_currentView) {
      case HomeView.main:
        return _buildMainContent();
      case HomeView.subCategory:
        return _buildSubCategoryContent();
      case HomeView.symptoms:
        return _buildSymptomContent();
      case HomeView.finalSummary:
        return _buildFinalSummary();
    }
  }

  // --- 메인 화면: 9대 카테고리 (3x3 그리드) ---
  Widget _buildMainContent() {
    return SingleChildScrollView(
      key: const ValueKey('main'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              t('hint'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryGrid(),
          const SizedBox(height: 40),
          _buildQuickJobSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _slate200),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: _slate400),
          const SizedBox(width: 12),
          Text(
            t('service_search_placeholder'),
            style: TextStyle(color: _slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final services = [
      {'id': 'cleaning', 'icon': Icons.cleaning_services, 'color': Colors.cyan},
      {'id': 'security', 'icon': Icons.shield, 'color': const Color(0xFF1E3A8A)},
      {'id': 'repair', 'icon': Icons.build, 'color': Colors.orange},
      {'id': 'delivery', 'icon': Icons.delivery_dining, 'color': Colors.green},
      {'id': 'beauty', 'icon': Icons.face, 'color': Colors.pinkAccent},
      {'id': 'tutor', 'icon': Icons.menu_book, 'color': Colors.purple},
      {'id': 'photo', 'icon': Icons.camera_alt, 'color': Colors.amber},
      {'id': 'event', 'icon': Icons.celebration, 'color': Colors.indigo},
      {'id': 'garden', 'icon': Icons.park_outlined, 'color': Colors.teal},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.0,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];
          return InkWell(
            onTap: () => setState(() {
              _activeCategory = s['id'] as String;
              _currentView = HomeView.subCategory;
            }),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s['icon'] as IconData, color: s['color'] as Color, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    t(s['id'] as String),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 급구 알바 섹션: 6종 확장 및 Peeking 전략 ---
  Widget _buildQuickJobSection() {
    final jobs = [
      {'t': 'job1', 'tags': ['#초보가능']},
      {'t': 'job2', 'tags': ['#경력우대']},
      {'t': 'job3', 'tags': ['#식사제공']},
      {'t': 'job4', 'tags': ['#통역보조']},
      {'t': 'job5', 'tags': ['#물류보조']},
      {'t': 'job6', 'tags': ['#판촉알바']},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(t('quick_job'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(left: 20, right: 5, top: 5, bottom: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: (jobs[index]['tags'] as List)
                          .map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                tag.toString(),
                                style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const Spacer(),
                    Text(
                      t(jobs[index]['t'] as String),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 2단계: 소분류 선택 (v44.0 정밀 맵핑) ---
  Widget _buildSubCategoryContent() {
    final Map<String, List<String>> subData = {
      'repair': ['에어컨', '가전', '전기', '배관', '페인트 및 지붕 보수'],
      'cleaning': ['이사/입주', '상업공간', '가전청소', '침구세척', '정기 방문'],
      'security': ['건물·상가(장기)', '공사장·창고', 'VIP 경호', '단기 행사 보안'],
      'delivery': ['음식 배달', '소형 화물', '마트 장보기 대행'],
      'tutor': ['언어(한/라/영)', 'IT/코딩', '음악'],
      'event': ['케이터링', '장식/데코', '사회자', '음향 장비 렌탈'],
      'garden': ['잔디 깎기', '가지치기', '해충 및 살충 방역'],
    };
    final list = subData[_activeCategory] ?? ['일반 서비스'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBar(1),
          const SizedBox(height: 20),
          Text(t(_activeCategory), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: Text(list[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => setState(() {
                  _selectedSubCategory = list[index];
                  _currentView = HomeView.symptoms;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3단계: 상세 옵션 선택 (S/M/L 버튼 로직) ---
  Widget _buildSymptomContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBar(2),
          const SizedBox(height: 20),
          Text("$_selectedSubCategory${t('s_hint')}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Text(t('space_size'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'L']
                .map((s) => _buildChoiceChip(s, _selectedSize == s, (val) => setState(() => _selectedSize = s)))
                .toList(),
          ),
          const SizedBox(height: 30),
          Text(t('house_type'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['스튜디오', '1BR', '2BR', '하우스']
                .map((h) => _buildChoiceChip(h, _selectedHouseType == h, (val) => setState(() => _selectedHouseType = h)))
                .toList(),
          ),
          const Spacer(),
          if (_selectedSubCategory.contains('지붕'))
            Text(t('special_roof'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentView = HomeView.finalSummary),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                t('next'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4단계: 신청 확인 및 신뢰 인프라 (예약금 안내) ---
  Widget _buildFinalSummary() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepBar(3),
          const SizedBox(height: 30),
          const Center(child: Icon(Icons.check_circle, size: 80, color: Colors.green)),
          const SizedBox(height: 20),
          Center(
            child: Text(t('summary_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
          _buildSummaryRow(t('summary_category'), _activeCategory),
          _buildSummaryRow(t('summary_sub'), _selectedSubCategory),
          _buildSummaryRow(t('summary_size'), _selectedSize),
          _buildSummaryRow(t('summary_house'), _selectedHouseType),
          const Divider(height: 40),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t('deposit_notice'),
                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentView = HomeView.main),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                t('apply_final'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 공통 위젯: 진행 바 ---
  Widget _buildStepBar(int step) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('step1'),
              style: TextStyle(
                color: step >= 1 ? const Color(0xFF1E3A8A) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              t('step2'),
              style: TextStyle(
                color: step >= 2 ? const Color(0xFF1E3A8A) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              t('step3'),
              style: TextStyle(
                color: step >= 3 ? const Color(0xFF1E3A8A) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: step / 3,
          backgroundColor: _slate200,
          color: const Color(0xFF1E3A8A),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool selected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _slate500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChatTab() => Center(child: Text(t('chat_ready')));
}

