import 'package:flutter/material.dart';
import 'package:lao_trust/services/firebase_service.dart';
import '../../core/app_localizations.dart';
import '../../core/location_service.dart';
import '../profile/profile_screen.dart';
import '../home/components/welcome_banner.dart';
import '../home/components/category_grid.dart';
import '../home/components/quick_jobs.dart';
import '../home/components/section_title_style.dart';
import '../home/components/radar_scanning_widget.dart';
import '../profile/widgets/commander_verified_badge.dart';
import '../profile/widgets/digital_partner_id_card.dart';
import '../../services/expert_availability_service.dart';

/// 홈 화면: 3단계(메인 카테고리 → 세부 종목 → 증상 선택) + 급구 알바 카드
/// 상단바 푸른색 #1E3A8A, 언어(한/라오/영) PopupMenuButton, 설정·알림 아이콘.
enum HomeView { main, subCategory, symptoms, cleaningOptions, otherSummary }

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

  HomeView _currentView = HomeView.main;
  // 선택 상태는 "표시 문자열"이 아닌 "키/ID"로 보관하여 언어 변경 시에도 상태가 깨지지 않게 한다.
  String _selectedCategoryKey = '';
  String _selectedSubCategoryId = '';

  // Cleaning 카테고리 전용: 2단계 선택 후 3단계(S/M/L) 진입
  String _selectedCleaningSubCategoryId = '';
  String _selectedCleaningSubCategoryLabelKey = '';
  String _selectedCleaningSize = '';
  String _selectedCleaningHouseType = '';

  // 경비/배달/기타 등 2단계 선택 후 요약 화면용
  String _selectedOtherSubCategoryLabelKey = '';

  // 증상도 표시 문자열이 아닌 키로 보관 (다국어 100% 변환 보장)
  final List<String> _selectedSymptomKeys = [];
  final TextEditingController _etcController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _shownDefaultLocationInfo = false;

  static const String _symptomOtherKey = 'symptom_other';

  // 서브카테고리 ID(언어 독립) -> 증상 키 리스트
  final Map<String, List<String>> _symptomKeyData = {
    'ac': ['symptom_ac_no_cold_air', 'symptom_ac_noise', 'symptom_ac_water_sound', 'symptom_ac_not_cool', _symptomOtherKey],
    'household': ['symptom_household_power', 'symptom_household_noise', 'symptom_household_stopped', 'symptom_household_broken', _symptomOtherKey],
    'electric': ['symptom_electric_breaker', 'symptom_electric_burn_smell', 'symptom_electric_flicker', 'symptom_electric_leak', _symptomOtherKey],
    'plumbing': ['symptom_plumbing_leak', 'symptom_plumbing_clog', 'symptom_plumbing_backflow', 'symptom_plumbing_low_pressure', _symptomOtherKey],
  };

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final (loc, usedDefault) = await getUserLocationOrDefault();
    if (!mounted) return;
    // ExpertCard 내부에서 거리 계산을 수행하므로, 여기서는 권한 안내만 유지한다.
    if (usedDefault && !_shownDefaultLocationInfo) {
      _shownDefaultLocationInfo = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n('location_permission_denied_vientiane_default'),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _etcController.dispose();
    _searchController.dispose();
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
      if (_currentView == HomeView.cleaningOptions) {
        _currentView = HomeView.subCategory;
      } else if (_currentView == HomeView.otherSummary) {
        _currentView = HomeView.subCategory;
      } else if (_currentView == HomeView.symptoms) {
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
                _selectedCleaningSubCategoryId = '';
                _selectedCleaningSubCategoryLabelKey = '';
                _selectedOtherSubCategoryLabelKey = '';
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

  static const Color _appBarBlue = Color(0xFF1E293B);

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarBlue,
      foregroundColor: Colors.white,
      surfaceTintColor: _appBarBlue,
      elevation: 0,
      toolbarHeight: 40,
      titleSpacing: 12,
      leading: _currentView != HomeView.main
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: _goBack,
            )
          : null,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final titleText = _currentView == HomeView.main
              ? context.l10n('app_bar_title')
              : context.l10n(_selectedCategoryKey);
          final screenWidth = MediaQuery.sizeOf(context).width;
          final fontSize = screenWidth < 380 ? 16.0 : 18.0;
          return Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      titleText,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      centerTitle: false,
      actions: [
        if (_currentView == HomeView.main)
          _HomeAccountStatusAction(
            onLoginTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileScreen(openPhoneAuthOnStart: true),
                ),
              );
            },
          ),
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
          onSelected: (value) {
            final label = switch (value) {
              'profile' => context.l10n('settings_my_profile'),
              'account' => context.l10n('settings_account'),
              'logout' => context.l10n('settings_logout'),
              _ => '',
            };
            if (label.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(label)),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'profile', child: Text(context.l10n('settings_my_profile'))),
            PopupMenuItem(value: 'account', child: Text(context.l10n('settings_account'))),
            PopupMenuItem(value: 'logout', child: Text(context.l10n('settings_logout'))),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          color: Colors.white,
          onSelected: (value) {
            final label = switch (value) {
              'system' => context.l10n('notif_system'),
              'activity' => context.l10n('notif_activity'),
              _ => '',
            };
            if (label.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(label)),
              );
            }
          },
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
      case HomeView.cleaningOptions:
        return _buildCleaningOptionsContent();
      case HomeView.otherSummary:
        return _buildOtherSummaryContent();
    }
  }

  Widget _buildMainContent() {
    return Column(
      key: const ValueKey('main'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentView == HomeView.main) const WelcomeBanner(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _buildSearchBar(context),
                const SizedBox(height: 4),
                Text(
                  context.l10n('section_expert_headline'),
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Sans',
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n('section_expert_services'),
                  style: kHomeSectionTitleTextStyle,
                ),
                const SizedBox(height: 2),
                CategoryGrid(
                  onCategorySelected: (labelKey) {
                    setState(() {
                      _selectedCategoryKey = labelKey;
                      _selectedCleaningSubCategoryId = '';
                      _selectedCleaningSubCategoryLabelKey = '';
                      _selectedOtherSubCategoryLabelKey = '';
                      _currentView = HomeView.subCategory;
                    });
                  },
                ),
                _buildNearbyExpertsSection(),
                const SizedBox(height: 8),
                QuickJobsSection(firebaseService: _firebaseService),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // 사령관 지침: [적용] 버튼 영구 제거 — 하단 여백은 알바 섹션·도트 배치에 활용
      ],
    );
  }

  Widget _buildNearbyExpertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n('experts_nearby_title'),
          style: kHomeSectionTitleTextStyle,
        ),
        const SizedBox(height: 4),
        _NearbyExpertsSectionBody(),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28.0),
        onTap: () => _openSearchDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
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
                    fontFamily: 'Noto Sans',
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearchDialog(BuildContext context) {
    _searchController.text = '';

    final cityKeys = <String>[
      'city_vientiane',
      'city_luang_prabang',
      'city_pakse',
      'city_savannakhet',
    ];
    final recommendedKeys = <String>[
      'search_keyword_move',
      'search_keyword_cleaning',
      'search_keyword_repair',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n('search_ready_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n('search_ready_body')),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: context.l10n('search_placeholder'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                if (_isMoveQuery(context, v)) {
                  Navigator.of(ctx).pop();
                  _goToCleaningSubCategory();
                }
              },
              onSubmitted: (v) {
                Navigator.of(ctx).pop();
                _handleSearchQuery(v);
              },
            ),
            const SizedBox(height: 16),
            Text(context.l10n('search_recommended'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in recommendedKeys)
                  ActionChip(
                    label: Text(context.l10n(k)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleSearchQuery(context.l10n(k));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.l10n('search_city_hint'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in cityKeys)
                  FilterChip(
                    label: Text(context.l10n(k)),
                    selected: false,
                    onSelected: (_) {},
                  ),
              ],
            ),
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

  void _handleSearchQuery(String query) {
    if (_isMoveQuery(context, query)) {
      _goToCleaningSubCategory();
      return;
    }
    if (_isAcQuery(query)) {
      _showAcChoiceDialog();
      return;
    }
    // 현재는 “준비 중” 단계로만 안내. (요구: AlertDialog 또는 추천어 노출)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(context.l10n('search_not_ready_yet')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }

  bool _isMoveQuery(BuildContext context, String raw) {
    final q = raw.toLowerCase();
    final trigger = context.l10n('search_keyword_move_trigger').toLowerCase();
    return q.contains(trigger) || q.contains('이사') || q.contains('moving') || q.contains('move') || q.contains('ຍ້າຍ');
  }

  bool _isAcQuery(String raw) {
    final q = raw.toLowerCase();
    return q.contains('에어컨') ||
        q.contains('aircon') ||
        q.contains('air conditioner') ||
        q.contains('ac ') ||
        q == 'ac' ||
        q.contains('ແອກ');
  }

  void _showAcChoiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n('search_ac_choice_title')),
        content: Text(context.l10n('search_ac_choice_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedCategoryKey = 'expert_repair';
                _selectedSubCategoryId = 'ac';
                _selectedSymptomKeys.clear();
                _etcController.clear();
                _currentView = HomeView.symptoms;
              });
            },
            child: Text(context.l10n('search_ac_choice_repair')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedCategoryKey = 'expert_cleaning';
                _selectedCleaningSubCategoryId = 'appliance';
                _selectedCleaningSubCategoryLabelKey = 'sub_cleaning_appliance';
                _selectedCleaningSize = '';
                _selectedCleaningHouseType = '';
                _currentView = HomeView.cleaningOptions;
              });
            },
            child: Text(context.l10n('search_ac_choice_cleaning')),
          ),
        ],
      ),
    );
  }

  void _goToCleaningSubCategory() {
    setState(() {
      _selectedCategoryKey = 'expert_cleaning';
      _selectedCleaningSubCategoryId = '';
      _selectedCleaningSubCategoryLabelKey = '';
      _selectedOtherSubCategoryLabelKey = '';
      _currentView = HomeView.subCategory;
    });
  }

  /// v44.0 복구: 전 카테고리 2단계(소분류) 리스트. 수리 로직은 기존 유지.
  static List<Map<String, String>> _getSubCategoryItems(String categoryKey) {
    switch (categoryKey) {
      case 'expert_repair':
        return [
          {'id': 'ac', 'labelKey': 'service_ac'},
          {'id': 'household', 'labelKey': 'service_household'},
          {'id': 'electric', 'labelKey': 'service_electric'},
          {'id': 'plumbing', 'labelKey': 'service_plumbing'},
        ];
      case 'expert_cleaning':
        return [
          {'id': 'move_in', 'labelKey': 'sub_cleaning_move_in'},
          {'id': 'commercial', 'labelKey': 'sub_cleaning_commercial'},
          {'id': 'appliance', 'labelKey': 'sub_cleaning_appliance'},
          {'id': 'bedding', 'labelKey': 'sub_cleaning_bedding'},
          {'id': 'regular_visit', 'labelKey': 'sub_cleaning_regular_visit'},
        ];
      case 'expert_security':
        return [
          {'id': 'building', 'labelKey': 'sub_security_building'},
          {'id': 'site', 'labelKey': 'sub_security_site'},
          {'id': 'vip', 'labelKey': 'sub_security_vip'},
          {'id': 'event', 'labelKey': 'sub_security_event'},
        ];
      case 'expert_delivery':
        return [
          {'id': 'food', 'labelKey': 'sub_delivery_food'},
          {'id': 'cargo', 'labelKey': 'sub_delivery_cargo'},
          {'id': 'mart', 'labelKey': 'sub_delivery_mart'},
        ];
      case 'expert_beauty':
        return [
          {'id': 'general', 'labelKey': 'sub_beauty_general'},
        ];
      case 'expert_tutoring':
        return [
          {'id': 'lang', 'labelKey': 'sub_tutor_lang'},
          {'id': 'it', 'labelKey': 'sub_tutor_it'},
          {'id': 'music', 'labelKey': 'sub_tutor_music'},
        ];
      case 'expert_photo':
        return [
          {'id': 'studio', 'labelKey': 'sub_photo_studio'},
          {'id': 'event', 'labelKey': 'sub_photo_event'},
        ];
      case 'expert_event':
        return [
          {'id': 'catering', 'labelKey': 'sub_event_catering'},
          {'id': 'deco', 'labelKey': 'sub_event_deco'},
          {'id': 'mc', 'labelKey': 'sub_event_mc'},
          {'id': 'sound', 'labelKey': 'sub_event_sound'},
        ];
      case 'expert_garden':
        return [
          {'id': 'lawn', 'labelKey': 'sub_garden_lawn'},
          {'id': 'trim', 'labelKey': 'sub_garden_trim'},
          {'id': 'pest', 'labelKey': 'sub_garden_pest'},
        ];
      default:
        return [{'id': 'general', 'labelKey': 'symptom_other'}];
    }
  }

  Widget _buildSubCategoryContent() {
    final subItems = _getSubCategoryItems(_selectedCategoryKey);
    final isRepair = _selectedCategoryKey == 'expert_repair';

    return Padding(
      key: ValueKey('sub_$_selectedCategoryKey'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('repair_subcategory_title'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n(_selectedCategoryKey),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: subItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = subItems[index];
                final String id = item['id']!;
                final String labelKey = item['labelKey']!;
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  title: Text(
                    context.l10n(labelKey),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF1E3A8A),
                  ),
                  onTap: () {
                    setState(() {
                      if (isRepair) {
                        _selectedSubCategoryId = id;
                        _selectedSymptomKeys.clear();
                        _etcController.clear();
                        _currentView = HomeView.symptoms;
                      } else if (_selectedCategoryKey == 'expert_cleaning') {
                        _selectedCleaningSubCategoryId = id;
                        _selectedCleaningSubCategoryLabelKey = labelKey;
                        _selectedCleaningSize = '';
                        _selectedCleaningHouseType = '';
                        _currentView = HomeView.cleaningOptions;
                      } else {
                        _selectedOtherSubCategoryLabelKey = labelKey;
                        _currentView = HomeView.otherSummary;
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSummaryContent() {
    return SingleChildScrollView(
      key: const ValueKey('other_summary'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n(_selectedCategoryKey),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n(_selectedOtherSubCategoryLabelKey),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _onStep3Submit,
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

  Widget _buildSymptomContent() {
    // 수리만 증상 선택. 청소는 2단계 선택 후 cleaningOptions으로 직행하므로 여기 오지 않음.
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

  // 급구 알바 섹션 및 매핑 로직은 분리된 컴포넌트로 이동됨.

  /// Cleaning 카테고리 전용 3뎁스: 공간 크기(S/M/L) + 주거 형태 버튼 (2단계 선택 후에만 진입)
  Widget _buildCleaningOptionsContent() {
    return SingleChildScrollView(
      key: ValueKey('cleaning_options_$_selectedCleaningSubCategoryId'),
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
          if (_selectedCleaningSubCategoryLabelKey.isNotEmpty)
            Text(
              context.l10n(_selectedCleaningSubCategoryLabelKey),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          if (_selectedCleaningSubCategoryLabelKey.isNotEmpty)
            const SizedBox(height: 8),
          Text(
            context.l10n('expert_cleaning'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n('repair_select_all_hint'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 25),
          Text(
            context.l10n('cleaning_size_s'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_size_s',
                isSelected: _selectedCleaningSize == 'S',
                onTap: () => setState(() => _selectedCleaningSize = 'S'),
              ),
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_size_m',
                isSelected: _selectedCleaningSize == 'M',
                onTap: () => setState(() => _selectedCleaningSize = 'M'),
              ),
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_size_l',
                isSelected: _selectedCleaningSize == 'L',
                onTap: () => setState(() => _selectedCleaningSize = 'L'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            context.l10n('cleaning_house_studio'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_house_studio',
                isSelected: _selectedCleaningHouseType == 'studio',
                onTap: () => setState(() => _selectedCleaningHouseType = 'studio'),
              ),
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_house_1br',
                isSelected: _selectedCleaningHouseType == '1br',
                onTap: () => setState(() => _selectedCleaningHouseType = '1br'),
              ),
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_house_2br',
                isSelected: _selectedCleaningHouseType == '2br',
                onTap: () => setState(() => _selectedCleaningHouseType = '2br'),
              ),
              _buildCleaningChoiceChip(
                labelKey: 'cleaning_house_house',
                isSelected: _selectedCleaningHouseType == 'house',
                onTap: () => setState(() => _selectedCleaningHouseType = 'house'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (_selectedCleaningSize.isNotEmpty && _selectedCleaningHouseType.isNotEmpty)
                  ? _onStep3Submit
                  : null,
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

  Widget _buildCleaningChoiceChip({
    required String labelKey,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(
            context.l10n(labelKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          selected: isSelected,
          selectedColor: const Color(0xFF1E3A8A),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          onSelected: (_) => onTap(),
        ),
      ),
    );
  }
}

class _HomeAccountStatusAction extends StatelessWidget {
  const _HomeAccountStatusAction({required this.onLoginTap});
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onLoginTap,
      tooltip: context.l10n('home_phone_login_short'),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle_outlined, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            context.l10n('home_phone_login_short'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

/// 근처 전문가 섹션 본문: 5km→15km→전역 Elastic 수색 + 레이더 애니메이션
class _NearbyExpertsSectionBody extends StatefulWidget {
  @override
  State<_NearbyExpertsSectionBody> createState() => _NearbyExpertsSectionBodyState();
}

class _NearbyExpertsSectionBodyState extends State<_NearbyExpertsSectionBody> {
  LocationPoint? _userLocation;
  List<ExpertProfile> _experts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (loc, _) = await getUserLocationOrDefault();
    if (!mounted) return;
    final result = await fetchExpertsElastic(loc);
    if (!mounted) return;
    setState(() {
      _userLocation = loc;
      _experts = result.experts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadarScanningWidget(
                size: 100,
                label: context.l10n('radar_expand_label'),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n('radar_searching'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    if (_experts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '근처에 대기 중인 전문가가 없습니다.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      );
    }
    return Column(
      children: _experts.map((e) {
        final loc = e.location!;
        final km = _userLocation != null ? distanceInKm(_userLocation!, loc) : 0.0;
        return ExpertCard(
          name: e.displayName,
          expertLocation: loc,
          icon: Icons.person,
          subtitle: context.l10n('experts_nearby_subtitle'),
          onTap: () {
            if (e.partnerSerialId != null && e.partnerSerialId!.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: DigitalPartnerIdCard(
                    serialId: e.partnerSerialId!,
                    displayName: e.displayName,
                    photoUrl: e.photoUrl,
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
          },
          commanderApproved: e.commanderApproved,
          partnerSerialId: e.partnerSerialId,
          photoUrl: e.photoUrl,
          distanceKm: km,
        );
      }).toList(),
    );
  }
}

class ExpertCard extends StatefulWidget {
  const ExpertCard({
    super.key,
    required this.name,
    required this.expertLocation,
    required this.icon,
    required this.subtitle,
    required this.onTap,
    this.commanderApproved = false,
    this.partnerSerialId,
    this.photoUrl,
    this.distanceKm,
  });

  final String name;
  final LocationPoint expertLocation;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;
  final bool commanderApproved;
  final String? partnerSerialId;
  final String? photoUrl;
  /// 미제공 시 내부에서 계산
  final double? distanceKm;

  @override
  State<ExpertCard> createState() => _ExpertCardState();
}

class _ExpertCardState extends State<ExpertCard> {
  double? _distanceKm;
  bool _isCalculating = true;

  @override
  void initState() {
    super.initState();
    if (widget.distanceKm != null) {
      _distanceKm = widget.distanceKm;
      _isCalculating = false;
    } else {
      _calcDistance();
    }
  }

  Future<void> _calcDistance() async {
    setState(() => _isCalculating = true);
    final (userLoc, _) = await getUserLocationOrDefault();
    final km = distanceInKm(userLoc, widget.expertLocation);
    if (!mounted) return;
    setState(() {
      _distanceKm = km;
      _isCalculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = _isCalculating
        ? context.l10n('distance_calculating')
        : context
            .l10n('distance_from_me')
            .replaceAll('{km}', (_distanceKm ?? 0).toStringAsFixed(1));

    Widget avatar = CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
      child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(widget.photoUrl!, fit: BoxFit.cover, width: 52, height: 52),
            )
          : Icon(widget.icon, color: const Color(0xFF1E3A8A)),
    );
    if (widget.commanderApproved) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          const Positioned(
            right: -2,
            bottom: -2,
            child: CommanderVerifiedBadgeChip(size: 22),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: avatar,
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Sans',
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              distanceText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
        onTap: widget.onTap,
      ),
    );
  }
}
