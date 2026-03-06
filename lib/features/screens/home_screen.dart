import 'package:flutter/material.dart';
import 'package:lao_trust/services/firebase_service.dart';
import '../../core/app_localizations.dart';

/// 홈 화면: 3단계(메인 카테고리 → 세부 종목 → 증상 선택) + 급구 알바 카드
/// 상단바 푸른색 #1E3A8A, 언어(한/라오/영) PopupMenuButton, 설정·알림 아이콘.
enum HomeView { main, subCategory, symptoms }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.locale,
    this.onLocaleChanged,
  });

  final Locale? locale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  HomeView _currentView = HomeView.main;
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  int _currentPage = 0;

  final List<String> _selectedSymptoms = [];
  final TextEditingController _etcController = TextEditingController();

  final Map<String, List<String>> _symptomData = {
    '에어컨': ['찬바람 안 나옴', '소음 발생', '물 새는 소리', '시원하지 않음', '기타'],
    '가전': ['전원 불량', '이상 소음', '작동 멈춤', '부품 파손', '기타'],
    '전기': ['차단기 내려감', '콘센트 탄 냄새', '조명 깜빡임', '누전 의심', '기타'],
    '배관': ['수도꼭지 누수', '하수구 막힘', '변기 역류', '수압 약함', '기타'],
  };

  @override
  void dispose() {
    _pageController.dispose();
    _etcController.dispose();
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
    );
  }

  void _goBack() {
    setState(() {
      if (_currentView == HomeView.symptoms) {
        _currentView = HomeView.subCategory;
      } else if (_currentView == HomeView.subCategory) {
        _currentView = HomeView.main;
      }
    });
  }

  /// 3단계 [다음 단계로] 클릭 시: 신청 완료 알림창 후 메인 복귀.
  /// 확장성 코드 매립:
  /// - [결제 시스템] 연동: 여기서 결제 단계 화면으로 이동하거나, 결제 API 호출 전 상태 저장.
  /// - [GPS 위치 정보] 연동: 신청 전/후 사용자 위치 수집 및 서버 전송 로직 추가.
  /// - [회원가입] 연동: 비로그인 사용자일 경우 로그인/회원가입 유도 후 신청 완료 처리.
  void _onStep3Submit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n('application_complete_title')),
        content: Text(context.l10n('application_complete_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentView = HomeView.main;
                _selectedCategory = '';
                _selectedSubCategory = '';
                _selectedSymptoms.clear();
                _etcController.clear();
              });
            },
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }

  static const Color _appBarBlue = Color(0xFF1E3A8A);

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarBlue,
      foregroundColor: Colors.white,
      surfaceTintColor: _appBarBlue,
      elevation: 0,
      leading: _currentView != HomeView.main
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: _goBack,
            )
          : null,
      title: Text(
        _currentView == HomeView.main ? 'LAO TRUST 🛡️' : _selectedCategory,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        if (widget.onLocaleChanged != null)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.public, color: Colors.white),
            tooltip: context.l10n('language'),
            color: Colors.white,
            onSelected: widget.onLocaleChanged!,
            itemBuilder: (context) => [
              PopupMenuItem(value: const Locale('ko'), child: Text(context.l10n('lang_ko'))),
              PopupMenuItem(value: const Locale('lo'), child: Text(context.l10n('lang_lo'))),
              PopupMenuItem(value: const Locale('en'), child: Text(context.l10n('lang_en'))),
            ],
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings, color: Colors.white),
          color: Colors.white,
          onSelected: (_) {},
          itemBuilder: (context) => [
            PopupMenuItem(value: 'profile', child: Text(context.l10n('settings_my_profile'))),
            PopupMenuItem(value: 'account', child: Text(context.l10n('settings_account'))),
            PopupMenuItem(value: 'logout', child: Text(context.l10n('settings_logout'))),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          color: Colors.white,
          onSelected: (_) {},
          itemBuilder: (context) => [
            PopupMenuItem(value: 'system', child: Text(context.l10n('notif_system'))),
            PopupMenuItem(value: 'activity', child: Text(context.l10n('notif_activity'))),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentBody() {
    switch (_currentView) {
      case HomeView.main:
        return _buildMainContent();
      case HomeView.subCategory:
        return _buildSubCategoryContent();
      case HomeView.symptoms:
        return _buildSymptomContent();
    }
  }

  Widget _buildMainContent() {
    return Column(
      key: const ValueKey('main'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(context),
                const SizedBox(height: 20),
                Text(
                  context.l10n('section_expert_headline'),
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n('section_expert_services'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildCategoryGrid(),
                const SizedBox(height: 40),
                _buildQuickJobSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildMainApplyButton(context),
      ],
    );
  }

  /// 상단바 바로 아래 하얀색 배경 검색창 (유지)
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 10),
          Text(
            context.l10n('search_placeholder'),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainApplyButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(context.l10n('apply'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, dynamic>> services = [
      {'name': '청소', 'icon': Icons.cleaning_services, 'color': Colors.cyan},
      {'name': '경비', 'icon': Icons.shield, 'color': const Color(0xFF1E3A8A)},
      {'name': '수리', 'icon': Icons.build, 'color': Colors.orange},
      {'name': '배달', 'icon': Icons.delivery_dining, 'color': Colors.green},
      {'name': '뷰티', 'icon': Icons.face, 'color': Colors.pinkAccent},
      {'name': '과외', 'icon': Icons.menu_book, 'color': Colors.purple},
      {'name': '사진', 'icon': Icons.camera_alt, 'color': Colors.amber},
      {'name': '이벤트', 'icon': Icons.celebration, 'color': Colors.indigo},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.85,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        final Color color = s['color'] as Color;
        return InkWell(
          onTap: () {
            if (s['name'] == '수리') {
              setState(() {
                _selectedCategory = '수리';
                _currentView = HomeView.subCategory;
              });
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(s['icon'] as IconData, color: color, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                s['name'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryContent() {
    final subItems = [
      {'name': '에어컨', 'icon': Icons.ac_unit},
      {'name': '가전', 'icon': Icons.settings},
      {'name': '전기', 'icon': Icons.electric_bolt},
      {'name': '배관', 'icon': Icons.plumbing},
    ];

    return Padding(
      key: const ValueKey('sub'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '세부 종목 선택',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.2,
            ),
            itemCount: subItems.length,
            itemBuilder: (context, index) {
              final item = subItems[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubCategory = item['name'] as String;
                    _currentView = HomeView.symptoms;
                    _selectedSymptoms.clear();
                    _etcController.clear();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: const Color(0xFF1E3A8A), size: 35),
                      const SizedBox(height: 10),
                      Text(
                        item['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomContent() {
    final symptoms = _symptomData[_selectedSubCategory] ?? ['기타'];

    return SingleChildScrollView(
      key: const ValueKey('symptoms'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Step 1 / 3',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: const LinearProgressIndicator(
                    value: 0.33,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            '$_selectedSubCategory에 어떤 증상이 있나요?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            '해당하는 항목을 모두 선택해 주세요.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 25),
          ...symptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  symptom,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                value: isSelected,
                activeColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSymptoms.add(symptom);
                    } else {
                      _selectedSymptoms.remove(symptom);
                    }
                  });
                },
              ),
            );
          }),
          if (_selectedSymptoms.contains('기타'))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _etcController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '상세 증상을 자유롭게 적어주세요.',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _selectedSymptoms.isNotEmpty ? _onStep3Submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '다음 단계로',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사령관 특별 지시: 데이터 부재 시에도 Mock 3종(식당 서버, 단순 노무, 카페 알바) 무조건 표시.
  static const List<Map<String, String>> _mockQuickJobs = [
    {'title': '식당 서버', 'loc': '비엔티안 시청 인근', 'tag': '급구'},
    {'title': '단순 노무', 'loc': '타락광장 근처', 'tag': '협의'},
    {'title': '카페 알바', 'loc': '시내 중심가', 'tag': '신규'},
  ];

  Widget _buildQuickJobSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            context.l10n('section_quick_jobs'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.getQuickJobs(),
          builder: (context, snapshot) {
            final List<Map<String, dynamic>> jobs;
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              jobs = snapshot.data!;
            } else {
              jobs = _mockQuickJobs.map((m) => {
                'title': m['title'],
                'loc': m['loc'],
                'tag': m['tag'],
              }).toList();
            }
            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return AnimatedScale(
                        scale: _currentPage == index ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['tag']?.toString() ?? '신규',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                job['title']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${job['loc'] ?? ''} | 일급 협의',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    jobs.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
