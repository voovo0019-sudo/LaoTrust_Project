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
  // 유지(스와이프+Peeking): 사령관 월요일 특급 — viewportFraction 0.48 (카드 2개 완전 노출, 3번째 4~5% Peeking)
  final PageController _pageController = PageController(viewportFraction: 0.48);

  HomeView _currentView = HomeView.main;
  // 선택 상태는 "표시 문자열"이 아닌 "키/ID"로 보관하여 언어 변경 시에도 상태가 깨지지 않게 한다.
  String _selectedCategoryKey = '';
  String _selectedSubCategoryId = '';
  int _currentPage = 0;

  // 증상도 표시 문자열이 아닌 키로 보관 (다국어 100% 변환 보장)
  final List<String> _selectedSymptomKeys = [];
  final TextEditingController _etcController = TextEditingController();

  static const String _symptomOtherKey = 'symptom_other';

  // 서브카테고리 ID(언어 독립) -> 증상 키 리스트
  final Map<String, List<String>> _symptomKeyData = {
    'ac': ['symptom_ac_no_cold_air', 'symptom_ac_noise', 'symptom_ac_water_sound', 'symptom_ac_not_cool', _symptomOtherKey],
    'household': ['symptom_household_power', 'symptom_household_noise', 'symptom_household_stopped', 'symptom_household_broken', _symptomOtherKey],
    'electric': ['symptom_electric_breaker', 'symptom_electric_burn_smell', 'symptom_electric_flicker', 'symptom_electric_leak', _symptomOtherKey],
    'plumbing': ['symptom_plumbing_leak', 'symptom_plumbing_clog', 'symptom_plumbing_backflow', 'symptom_plumbing_low_pressure', _symptomOtherKey],
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
                _selectedCategoryKey = '';
                _selectedSubCategoryId = '';
                _selectedSymptomKeys.clear();
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
        _currentView == HomeView.main
            ? context.l10n('app_bar_title')
            : context.l10n(_selectedCategoryKey),
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
                const SizedBox(height: 20),
                _buildQuickJobSection(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // 사령관 지침: [적용] 버튼 영구 제거 — 하단 여백은 알바 섹션·도트 배치에 활용
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
          Expanded(
            child: Text(
              context.l10n('search_placeholder'),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, dynamic>> services = [
      // 유지: 아이콘/색상/그리드 구성은 절대 변경하지 않음. (라벨만 i18n 키로 표시)
      {'key': 'expert_cleaning', 'icon': Icons.cleaning_services, 'color': Colors.cyan},
      {'key': 'expert_security', 'icon': Icons.shield, 'color': const Color(0xFF1E3A8A)},
      {'key': 'expert_repair', 'icon': Icons.build, 'color': Colors.orange},
      {'key': 'expert_delivery', 'icon': Icons.delivery_dining, 'color': Colors.green},
      {'key': 'expert_beauty', 'icon': Icons.face, 'color': Colors.pinkAccent},
      {'key': 'expert_tutoring', 'icon': Icons.menu_book, 'color': Colors.purple},
      {'key': 'expert_photo', 'icon': Icons.camera_alt, 'color': Colors.amber},
      {'key': 'expert_event', 'icon': Icons.celebration, 'color': Colors.indigo},
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
        final String labelKey = s['key'] as String;
        return InkWell(
          onTap: () {
            if (labelKey == 'expert_repair') {
              setState(() {
                _selectedCategoryKey = 'expert_repair';
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
                context.l10n(labelKey),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryContent() {
    final subItems = [
      // 서브카테고리도 ID로 보관하여 언어 변경 시 유지
      {'id': 'ac', 'labelKey': 'service_ac', 'icon': Icons.ac_unit},
      {'id': 'household', 'labelKey': 'service_household', 'icon': Icons.settings},
      {'id': 'electric', 'labelKey': 'service_electric', 'icon': Icons.electric_bolt},
      {'id': 'plumbing', 'labelKey': 'service_plumbing', 'icon': Icons.plumbing},
    ];

    return Padding(
      key: const ValueKey('sub'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('repair_subcategory_title'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
              final String id = item['id'] as String;
              final String labelKey = item['labelKey'] as String;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubCategoryId = id;
                    _currentView = HomeView.symptoms;
                    _selectedSymptomKeys.clear();
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
                        context.l10n(labelKey),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
    final symptomKeys = _symptomKeyData[_selectedSubCategoryId] ?? [_symptomOtherKey];
    final String questionKey = switch (_selectedSubCategoryId) {
      'ac' => 'repair_question_ac',
      'household' => 'repair_question_household',
      'electric' => 'repair_question_electric',
      'plumbing' => 'repair_question_plumbing',
      _ => 'repair_question_generic',
    };

    return SingleChildScrollView(
      key: const ValueKey('symptoms'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n('repair_step_label'),
                style: const TextStyle(
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
            context.l10n(questionKey),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n('repair_select_all_hint'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 25),
          ...symptomKeys.map((symptomKey) {
            final isSelected = _selectedSymptomKeys.contains(symptomKey);
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
                  context.l10n(symptomKey),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                value: isSelected,
                activeColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSymptomKeys.add(symptomKey);
                    } else {
                      _selectedSymptomKeys.remove(symptomKey);
                    }
                  });
                },
              ),
            );
          }),
          if (_selectedSymptomKeys.contains(_symptomOtherKey))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _etcController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.l10n('repair_other_hint'),
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
              onPressed: _selectedSymptomKeys.isNotEmpty ? _onStep3Submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                context.l10n('next_step'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사령관 특별 지시: 데이터 부재 시에도 Mock 3종(식당 서버, 단순 노무, 카페 알바) 무조건 표시.
  static const List<Map<String, String>> _mockQuickJobs = [
    // 키 기반으로 100% 번역 가능하게 구성
    {
      'titleKey': 'job_title_restaurant_server',
      'locKey': 'location_near_vientiane_hall',
      'salaryKey': 'salary_15k_per_hour',
      'detailKey': 'job_detail_restaurant_server',
    },
    {
      'titleKey': 'job_title_simple_labor',
      'locKey': 'location_near_that_luang',
      'salaryKey': 'salary_negotiable',
      'detailKey': 'job_detail_simple_labor',
    },
    {
      'titleKey': 'job_title_cafe_part_time',
      'locKey': 'location_downtown',
      'salaryKey': 'salary_12k_per_hour',
      'detailKey': 'job_detail_cafe_part_time',
    },
  ];

  // Firebase에서 문자열로 들어오는 경우(예: '식당 서버')도 가능한 한 키로 매핑하여 번역한다.
  // 누락 방지용 사전(Map) — 요구사항(1) 준수.
  static const Map<String, String> _jobTitleValueToKey = {
    '식당 서버': 'job_title_restaurant_server',
    '단순 노무': 'job_title_simple_labor',
    '카페 알바': 'job_title_cafe_part_time',
    '배달 도우미': 'job_title_delivery_helper',
  };
  static const Map<String, String> _jobLocValueToKey = {
    '비엔티안 시청 인근': 'location_near_vientiane_hall',
    '타락광장 근처': 'location_near_that_luang',
    '시내 중심가': 'location_downtown',
    '시내': 'location_downtown',
  };
  static const Map<String, String> _jobSalaryValueToKey = {
    '15,000 LAK/시간': 'salary_15k_per_hour',
    '12,000 LAK/시간': 'salary_12k_per_hour',
    '협의': 'salary_negotiable',
  };
  static const Map<String, String> _jobDetailValueToKey = {
    '식당 서버': 'job_detail_restaurant_server',
    '단순 노무': 'job_detail_simple_labor',
    '카페 알바': 'job_detail_cafe_part_time',
  };

  String _localizedFromMaybeKey(BuildContext context, Object? maybeKeyOrValue, Map<String, String> valueToKey) {
    if (maybeKeyOrValue == null) return '';
    final raw = maybeKeyOrValue.toString();
    final key = valueToKey[raw];
    return key == null ? raw : context.l10n(key);
  }

  void _showQuickJobDetailsDialog(BuildContext context, {required String title, required String location, required String salary, required String detail}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.l10n('job_detail_location')}: $location'),
            const SizedBox(height: 8),
            Text('${context.l10n('job_detail_salary')}: $salary'),
            const SizedBox(height: 8),
            Text('${context.l10n('job_detail_description')}: $detail'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }

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
                'titleKey': m['titleKey'],
                'locKey': m['locKey'],
                'salaryKey': m['salaryKey'],
                'detailKey': m['detailKey'],
              }).toList();
            }
            return Column(
              children: [
                SizedBox(
                  // UI Diet: 카드 슬림 + 좌측 밀착(padEnds: false)
                  height: 76,
                  child: PageView.builder(
                    controller: _pageController,
                    padEnds: false,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final title = job.containsKey('titleKey')
                          ? context.l10n(job['titleKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(context, job['title'], _jobTitleValueToKey);
                      final location = job.containsKey('locKey')
                          ? context.l10n(job['locKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(context, job['loc'], _jobLocValueToKey);
                      final salary = job.containsKey('salaryKey')
                          ? context.l10n(job['salaryKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(context, job['salary'], _jobSalaryValueToKey);
                      final detail = job.containsKey('detailKey')
                          ? context.l10n(job['detailKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(context, title, _jobDetailValueToKey);
                      return AnimatedScale(
                        scale: _currentPage == index ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => _showQuickJobDetailsDialog(
                              context,
                              title: title,
                              location: location,
                              salary: salary,
                              detail: detail,
                            ),
                            child: Row(
                              children: [
                                // 메인 카드 노출: [URGENT 태그] + [제목] (가로 다이어트: Expanded 제거, 아이콘 글자 바로 옆)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Text(
                                    context.l10n('tag_deadline_soon'),
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A), size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    jobs.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentPage = index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 22 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(28),
                        ),
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
