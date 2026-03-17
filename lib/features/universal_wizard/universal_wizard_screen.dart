// =============================================================================
// v1.3: 유니버설 4단계 위저드 화면 (9대 카테고리 공통)
// 1: 세부유형 선택 → 2: 규모/대상 → 3: 시각적 가이드 → 4: 확정·정산 가이드
// 디자인 헌법: 곡률 28.0px, 로얄 네이비 #1E293B. 홈 레이아웃 무변경.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import 'universal_wizard_config.dart';
import 'universal_wizard_state.dart';
import 'widgets/settlement_guide_widget.dart';

class UniversalWizardScreen extends StatefulWidget {
  const UniversalWizardScreen({
    super.key,
    required this.categoryKey,
    this.initialSubTypeId,
    this.initialSubTypeLabel,
  });

  static const String routeName = '/universal-wizard';
  final String categoryKey;
  final String? initialSubTypeId;
  final String? initialSubTypeLabel;

  @override
  State<UniversalWizardScreen> createState() => _UniversalWizardScreenState();
}

class _UniversalWizardScreenState extends State<UniversalWizardScreen> {
  static const int totalSteps = 4;
  late PageController _pageController;
  late UniversalWizardState _state;
  UniversalWizardConfig? _config;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _config = kUniversalWizardConfigs[widget.categoryKey];
    _state = UniversalWizardState(
      categoryKey: widget.categoryKey,
      step1SubTypeId: widget.initialSubTypeId ?? '',
      step1SubTypeLabel: widget.initialSubTypeLabel ?? '',
    );
    if (widget.initialSubTypeId != null && widget.initialSubTypeId!.isNotEmpty) {
      _currentStep = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  bool _canProceedStep1() => _state.step1SubTypeId.isNotEmpty;
  bool _canProceedStep2() {
    if (_config == null) return true;
    if (_config!.step2ChoiceType == Step2ChoiceType.none) return true;
    return _state.step2SelectedId.isNotEmpty;
  }
  bool _canProceedStep3() => true;
  bool _canProceedStep4() => true;

  Future<void> _submit() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n('application_complete_title')),
        content: Text(context.l10n('application_complete_message')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _config ?? kUniversalWizardConfigs['expert_repair']!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: UniversalWizardConfig.royalNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _goBack,
        ),
        title: Text(
          context.l10n(config.categoryKey),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildStep1(config),
                _buildStep2(config),
                _buildStep3(config),
                _buildStep4(config),
              ],
            ),
          ),
          _buildBottomButton(config),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Step ${_currentStep + 1} / $totalSteps',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: UniversalWizardConfig.royalNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / totalSteps,
                backgroundColor: UniversalWizardConfig.royalNavy.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(UniversalWizardConfig.royalNavy),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '세부 서비스 유형을 선택하세요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 20),
          ...config.step1SubTypes.map((e) {
            final selected = _state.step1SubTypeId == e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _state = _state.copyWith(step1SubTypeId: e.key, step1SubTypeLabel: e.value)),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? UniversalWizardConfig.royalNavy.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: selected ? UniversalWizardConfig.royalNavy : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? UniversalWizardConfig.royalNavy : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: UniversalWizardConfig.royalNavy))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep2(UniversalWizardConfig config) {
    if (config.step2ChoiceType == Step2ChoiceType.none || config.step2Ids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '이 카테고리는 규모 선택을 건너뜁니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '규모 또는 대상을 선택하세요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 20),
          ...List.generate(config.step2Ids.length, (i) {
            final id = config.step2Ids[i];
            final label = i < config.step2Labels.length ? config.step2Labels[i] : id;
            final selected = _state.step2SelectedId == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _state = _state.copyWith(step2SelectedId: id, step2SelectedLabel: label)),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? UniversalWizardConfig.royalNavy.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: selected ? UniversalWizardConfig.royalNavy : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? UniversalWizardConfig.royalNavy : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: UniversalWizardConfig.royalNavy))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep3(UniversalWizardConfig config) {
    switch (config.visualGuideType) {
      case VisualGuideType.photoUpload:
        return _buildStep3PhotoUpload(config);
      case VisualGuideType.mapPick:
        return _buildStep3MapPick(config);
      case VisualGuideType.textFields:
        return _buildStep3TextFields(config);
      case VisualGuideType.symptomAndNote:
        return _buildStep3SymptomAndNote(config);
    }
  }

  Widget _buildStep3PhotoUpload(UniversalWizardConfig config) {
    final slots = config.photoSlotCount.clamp(1, 10);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '원하는 스타일 또는 고장 부위 사진을 올려주세요 (증거 가치)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 12),
          Text(
            '최대 $slots장까지 업로드할 수 있습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(slots, (i) {
              final hasPhoto = i < _state.step3PhotoPaths.length;
              return InkWell(
                onTap: () {
                  final paths = List<String>.from(_state.step3PhotoPaths);
                  if (hasPhoto) {
                    paths.removeAt(i);
                  } else {
                    paths.add('placeholder_$i');
                    if (paths.length > slots) paths.removeLast();
                  }
                  setState(() => _state = _state.copyWith(step3PhotoPaths: paths));
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: hasPhoto ? UniversalWizardConfig.royalNavy.withValues(alpha: 0.15) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.3)),
                  ),
                  child: hasPhoto
                      ? const Icon(Icons.check_circle, color: UniversalWizardConfig.royalNavy, size: 36)
                      : Icon(Icons.add_photo_alternate, color: Colors.grey.shade600, size: 36),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (v) => setState(() => _state = _state.copyWith(step3ExtraNote: v)),
            decoration: InputDecoration(
              labelText: '추가 요청사항',
              hintText: '전문가에게 전달할 메모',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3MapPick(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '출발지와 도착지를 지도에서 찍어주세요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 12),
          Text(
            '지도 연동은 추후 구현됩니다. 아래 버튼으로 위치를 선택할 수 있습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text('지도 터치로 출발/도착 지정', style: TextStyle(color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.trip_origin, size: 20),
                  label: const Text('출발지'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UniversalWizardConfig.royalNavy,
                    side: const BorderSide(color: UniversalWizardConfig.royalNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.location_on, size: 20),
                  label: const Text('도착지'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UniversalWizardConfig.royalNavy,
                    side: const BorderSide(color: UniversalWizardConfig.royalNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3TextFields(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '학습 목표와 희망 스케줄을 입력하세요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _state = _state.copyWith(step3LearningGoal: v)),
            decoration: InputDecoration(
              labelText: '학습 목표',
              hintText: '예: 기초 회화, 시험 대비',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _state = _state.copyWith(step3Schedule: v)),
            decoration: InputDecoration(
              labelText: '희망 스케줄',
              hintText: '예: 주말 오전, 평일 저녁',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3SymptomAndNote(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '요구사항 및 추가 메모',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _state = _state.copyWith(step3ExtraNote: v)),
            decoration: InputDecoration(
              labelText: '추가 요청사항',
              hintText: '전문가에게 전달할 메모',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '요청 요약 확인',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: UniversalWizardConfig.royalNavy),
          ),
          const SizedBox(height: 20),
          _summaryRow('카테고리', context.l10n(config.categoryKey)),
          _summaryRow('세부 유형', _state.step1SubTypeLabel),
          if (_state.step2SelectedLabel.isNotEmpty) _summaryRow('규모/대상', _state.step2SelectedLabel),
          if (_state.step3ExtraNote.isNotEmpty) _summaryRow('추가 메모', _state.step3ExtraNote),
          const SizedBox(height: 24),
          const SettlementGuideWidget(),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
          Expanded(child: Text(value, style: const TextStyle(color: UniversalWizardConfig.royalNavy))),
        ],
      ),
    );
  }

  Widget _buildBottomButton(UniversalWizardConfig config) {
    bool canProceed = false;
    switch (_currentStep) {
      case 0:
        canProceed = _canProceedStep1();
        break;
      case 1:
        canProceed = _canProceedStep2();
        break;
      case 2:
        canProceed = _canProceedStep3();
        break;
      case 3:
        canProceed = _canProceedStep4();
        break;
    }
    final isLast = _currentStep == totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canProceed ? _goNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: UniversalWizardConfig.royalNavy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(isLast ? context.l10n('apply_final') : context.l10n('next_step')),
          ),
        ),
      ),
    );
  }
}
