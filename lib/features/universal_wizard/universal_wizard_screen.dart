// =============================================================================
// v1.3: 유니버설 4단계 위저드 화면 (9대 카테고리 공통)
// 1: 세부유형 선택 → 2: 규모/대상 → 3: 시각적 가이드 → 4: 확정·정산 가이드
// 디자인 헌법: 곡률 28.0px, 로얄 네이비 #1E293B. 홈 레이아웃 무변경.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/app_localizations.dart';
import '../../core/search_trigger_bus.dart';
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

/// 지침 v3.9: 알바 구인 등록과 동일한 선명한 로얄 블루 (아웃라인 버튼용)
const Color _kRoyalBlue = Color(0xFF1E3A8A);

class _UniversalWizardScreenState extends State<UniversalWizardScreen> {
  static const int totalSteps = 4;
  late PageController _pageController;
  late UniversalWizardState _state;
  UniversalWizardConfig? _config;
  int _currentStep = 0;

  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _pickedImages = <XFile>[];

  final Set<String> _step2Selections = <String>{};
  bool _step2OtherSelected = false;
  final TextEditingController _step2OtherController = TextEditingController();

  // Delivery / numeric inputs etc.
  final TextEditingController _weightKgController = TextEditingController();
  final TextEditingController _distanceKmController = TextEditingController();
  String _cargoSize = '';

  // Cleaning
  final TextEditingController _cleaningAreaController = TextEditingController();
  String _cleaningScale = '';

  // Tutoring
  final Set<String> _tutoringLevels = <String>{};

  // Security
  final TextEditingController _securityPeopleController = TextEditingController();
  final TextEditingController _securityTimeController = TextEditingController();

  // Garden
  String _gardenScale = '';
  final Set<String> _gardenScopes = <String>{};

  // Event
  final TextEditingController _eventPeopleController = TextEditingController();

  // Photo
  final TextEditingController _photoTimeController = TextEditingController();
  final Set<String> _photoPlaceSelections = <String>{};

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
    _step2OtherController.dispose();
    _weightKgController.dispose();
    _distanceKmController.dispose();
    _cleaningAreaController.dispose();
    _securityPeopleController.dispose();
    _securityTimeController.dispose();
    _eventPeopleController.dispose();
    _photoTimeController.dispose();
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
  bool _canProceedStep2() => _isStep2Complete();
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
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // v2.2: 레이더는 오직 신청 완료 시점에만 트리거
              SearchTriggerBus.trigger();
              Navigator.of(context).pop(true);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kRoyalBlue,
              side: const BorderSide(color: _kRoyalBlue, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
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

  bool _isStep2Complete() {
    final categoryKey = _state.categoryKey;
    switch (categoryKey) {
      case 'expert_delivery':
        return _weightKgController.text.trim().isNotEmpty &&
            _distanceKmController.text.trim().isNotEmpty &&
            _cargoSize.isNotEmpty;
      case 'expert_cleaning':
        return _cleaningAreaController.text.trim().isNotEmpty || _cleaningScale.isNotEmpty;
      case 'expert_tutoring':
        return _tutoringLevels.isNotEmpty;
      case 'expert_security':
        return _securityPeopleController.text.trim().isNotEmpty &&
            _securityTimeController.text.trim().isNotEmpty;
      case 'expert_garden':
        return _gardenScale.isNotEmpty || _gardenScopes.isNotEmpty;
      case 'expert_event':
        return _eventPeopleController.text.trim().isNotEmpty;
      case 'expert_photo':
        return _photoTimeController.text.trim().isNotEmpty && _photoPlaceSelections.isNotEmpty;
      case 'expert_beauty':
      case 'expert_repair':
        return _step2Selections.isNotEmpty || _step2OtherSelected;
      default:
        return _step2Selections.isNotEmpty || _step2OtherSelected;
    }
  }

  InputDecoration _outlineFieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: _kRoyalBlue, width: 1.2),
      ),
    );
  }

  Widget _outlineToggleTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? _kRoyalBlue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? _kRoyalBlue : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: _kRoyalBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _photoPromptForCategory() {
    switch (_state.categoryKey) {
      case 'expert_repair':
        return '고장 부위 또는 모델명 사진을 올려주세요';
      case 'expert_delivery':
        return '운송할 물품 또는 목록 사진을 올려주세요';
      case 'expert_beauty':
        return '원하는 스타일의 참고 사진을 올려주세요';
      case 'expert_photo':
        return '원하는 촬영 컨셉의 참고 사진을 올려주세요';
      case 'expert_cleaning':
        return '청소가 필요한 현장의 사진을 올려주세요';
      case 'expert_tutoring':
        return '교재 또는 학습 목표 사진을 올려주세요';
      case 'expert_security':
        return '배치 장소 또는 관련 서류 사진을 올려주세요';
      case 'expert_garden':
        return '정원 현장의 상태를 알 수 있는 사진을 올려주세요';
      case 'expert_event':
        return '행사 장소 또는 기획안 사진을 올려주세요';
      default:
        return '관련 사진을 올려주세요';
    }
  }

  Future<void> _pickImagesFromGallery({required int maxCount}) async {
    final remaining = (maxCount - _pickedImages.length).clamp(0, maxCount);
    if (remaining <= 0) return;
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    if (images.isEmpty) return;
    setState(() {
      _pickedImages.addAll(images.take(remaining));
      _state = _state.copyWith(step3PhotoPaths: _pickedImages.map((e) => e.path).toList());
    });
  }

  Future<void> _pickImageFromCamera({required int maxCount}) async {
    if (_pickedImages.length >= maxCount) return;
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    if (image == null) return;
    setState(() {
      _pickedImages.add(image);
      _state = _state.copyWith(step3PhotoPaths: _pickedImages.map((e) => e.path).toList());
    });
  }

  void _removePickedImageAt(int index) {
    if (index < 0 || index >= _pickedImages.length) return;
    setState(() {
      _pickedImages.removeAt(index);
      _state = _state.copyWith(step3PhotoPaths: _pickedImages.map((e) => e.path).toList());
    });
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
              color: _kRoyalBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / totalSteps,
                backgroundColor: _kRoyalBlue.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(_kRoyalBlue),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
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
                      color: selected ? _kRoyalBlue.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: selected ? _kRoyalBlue : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? _kRoyalBlue : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: _kRoyalBlue))),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상세 선택 및 추가 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 12),
          ..._buildStep2FieldsByCategory(),
        ],
      ),
    );
  }

  List<Widget> _buildStep2FieldsByCategory() {
    final categoryKey = _state.categoryKey;
    switch (categoryKey) {
      case 'expert_delivery':
        return _buildStep2Delivery();
      case 'expert_cleaning':
        return _buildStep2Cleaning();
      case 'expert_tutoring':
        return _buildStep2Tutoring();
      case 'expert_security':
        return _buildStep2Security();
      case 'expert_garden':
        return _buildStep2Garden();
      case 'expert_event':
        return _buildStep2Event();
      case 'expert_photo':
        return _buildStep2Photo();
      case 'expert_beauty':
        return _buildStep2Beauty();
      case 'expert_repair':
        return _buildStep2Repair();
      default:
        return _buildStep2GenericMultiSelect();
    }
  }

  List<Widget> _buildStep2Repair() {
    final sub = _state.step1SubTypeId;
    final options = switch (sub) {
      'ac' => ['찬바람 안 나옴', '소음', '물 떨어짐', '냉방 약함'],
      'electric' => ['차단기 내려감', '탄 냄새', '전등 깜빡임', '누전 의심'],
      'plumbing' => ['누수', '막힘', '역류', '수압 약함'],
      'roof' => ['페인트 벗겨짐', '누수/방수', '균열/보수'],
      _ => ['증상 선택'],
    };
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: o,
            selected: _step2Selections.contains(o),
            onTap: () => setState(() {
              if (_step2Selections.contains(o)) {
                _step2Selections.remove(o);
              } else {
                _step2Selections.add(o);
              }
            }),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _outlineToggleTile(
          label: '기타',
          selected: _step2OtherSelected,
          onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
        ),
      ),
      if (_step2OtherSelected)
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '증상/요구사항을 입력하세요'),
          maxLines: 2,
        ),
    ];
  }

  List<Widget> _buildStep2Delivery() {
    return [
      TextField(
        controller: _weightKgController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration('무게(kg)', hint: '예: 3'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _distanceKmController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration('거리(km)', hint: '예: 5'),
      ),
      const SizedBox(height: 12),
      const Text('짐 크기(S/M/L)', style: TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _outlineToggleTile(
              label: 'S',
              selected: _cargoSize == 'S',
              onTap: () => setState(() => _cargoSize = _cargoSize == 'S' ? '' : 'S'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: 'M',
              selected: _cargoSize == 'M',
              onTap: () => setState(() => _cargoSize = _cargoSize == 'M' ? '' : 'M'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: 'L',
              selected: _cargoSize == 'L',
              onTap: () => setState(() => _cargoSize = _cargoSize == 'L' ? '' : 'L'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 장보기 목록, 특이사항'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Beauty() {
    const options = ['컷', '펌', '관리', '네일', '메이크업'];
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: o,
            selected: _step2Selections.contains(o),
            onTap: () => setState(() {
              if (_step2Selections.contains(o)) {
                _step2Selections.remove(o);
              } else {
                _step2Selections.add(o);
              }
            }),
          ),
        ),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 염색, 두피 케어 등'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Photo() {
    return [
      TextField(
        controller: _photoTimeController,
        decoration: _outlineFieldDecoration('촬영 시간', hint: '예: 2시간 / 반나절 / 1일'),
        maxLines: 1,
      ),
      const SizedBox(height: 12),
      const Text('촬영 장소', style: TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue)),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '실내',
        selected: _photoPlaceSelections.contains('실내'),
        onTap: () => setState(() {
          if (_photoPlaceSelections.contains('실내')) {
            _photoPlaceSelections.remove('실내');
          } else {
            _photoPlaceSelections.add('실내');
          }
        }),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '야외',
        selected: _photoPlaceSelections.contains('야외'),
        onTap: () => setState(() {
          if (_photoPlaceSelections.contains('야외')) {
            _photoPlaceSelections.remove('야외');
          } else {
            _photoPlaceSelections.add('야외');
          }
        }),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 스튜디오/야외 특정 장소'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Cleaning() {
    return [
      TextField(
        controller: _cleaningAreaController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration('평수/면적(m² 또는 평)', hint: '예: 30평 / 60㎡'),
      ),
      const SizedBox(height: 12),
      const Text('규모 선택(S/M/L)', style: TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _outlineToggleTile(
              label: 'S',
              selected: _cleaningScale == 'S',
              onTap: () => setState(() => _cleaningScale = _cleaningScale == 'S' ? '' : 'S'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: 'M',
              selected: _cleaningScale == 'M',
              onTap: () => setState(() => _cleaningScale = _cleaningScale == 'M' ? '' : 'M'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: 'L',
              selected: _cleaningScale == 'L',
              onTap: () => setState(() => _cleaningScale = _cleaningScale == 'L' ? '' : 'L'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 특정 오염/특이사항'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Tutoring() {
    const levels = ['초등', '중등', '고등', '성인'];
    return [
      const Text('학습 레벨(복수 선택 가능)', style: TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue)),
      const SizedBox(height: 10),
      for (final l in levels) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: l,
            selected: _tutoringLevels.contains(l),
            onTap: () => setState(() {
              if (_tutoringLevels.contains(l)) {
                _tutoringLevels.remove(l);
              } else {
                _tutoringLevels.add(l);
              }
            }),
          ),
        ),
      ],
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 대학/직장인/자격증 대비'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Security() {
    return [
      TextField(
        controller: _securityPeopleController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration('투입 인원(명)', hint: '예: 2'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _securityTimeController,
        decoration: _outlineFieldDecoration('희망 시간', hint: '예: 09:00~18:00 / 3시간'),
        maxLines: 1,
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 복장/장비/특이사항'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Garden() {
    const scopes = ['잔디', '조경/식재', '나무 전지', '전체'];
    return [
      const Text('정원 크기(S/M/L)', style: TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _outlineToggleTile(
              label: 'S',
              selected: _gardenScale == 'S',
              onTap: () => setState(() => _gardenScale = _gardenScale == 'S' ? '' : 'S'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: 'M',
              selected: _gardenScale == 'M',
              onTap: () => setState(() => _gardenScale = _gardenScale == 'M' ? '' : 'M'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: 'L',
              selected: _gardenScale == 'L',
              onTap: () => setState(() => _gardenScale = _gardenScale == 'L' ? '' : 'L'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text('작업 범위(복수 선택 가능)', style: TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue)),
      const SizedBox(height: 10),
      for (final s in scopes)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: s,
            selected: _gardenScopes.contains(s),
            onTap: () => setState(() {
              if (_gardenScopes.contains(s)) {
                _gardenScopes.remove(s);
              } else {
                _gardenScopes.add(s);
              }
            }),
          ),
        ),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 특정 구역/특이사항'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Event() {
    return [
      TextField(
        controller: _eventPeopleController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration('예상 인원수', hint: '예: 30'),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)', hint: '예: 예산/컨셉/특이사항'),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2GenericMultiSelect() {
    const options = ['옵션 1', '옵션 2', '옵션 3'];
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: o,
            selected: _step2Selections.contains(o),
            onTap: () => setState(() {
              if (_step2Selections.contains(o)) {
                _step2Selections.remove(o);
              } else {
                _step2Selections.add(o);
              }
            }),
          ),
        ),
      _outlineToggleTile(
        label: '기타',
        selected: _step2OtherSelected,
        onTap: () => setState(() => _step2OtherSelected = !_step2OtherSelected),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration('기타(직접 입력)'),
          maxLines: 2,
        ),
      ],
    ];
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
    final slots = config.photoSlotCount.clamp(1, 5);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _photoPromptForCategory(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 12),
          Text(
            '최대 $slots장까지 업로드할 수 있습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImagesFromGallery(maxCount: slots),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('갤러리'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kRoyalBlue,
                    side: const BorderSide(color: _kRoyalBlue, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImageFromCamera(maxCount: slots),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('카메라'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kRoyalBlue,
                    side: const BorderSide(color: _kRoyalBlue, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(slots, (i) {
              final hasPhoto = i < _pickedImages.length;
              final image = hasPhoto ? _pickedImages[i] : null;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kRoyalBlue.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: hasPhoto
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: kIsWeb
                                ? Image.network(image!.path, fit: BoxFit.cover)
                                : Image.file(File(image!.path), fit: BoxFit.cover),
                          )
                        : Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade600, size: 34),
                  ),
                  if (hasPhoto)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: InkWell(
                        onTap: () => _removePickedImageAt(i),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kRoyalBlue, width: 1.2),
                          ),
                          child: const Icon(Icons.close, size: 16, color: _kRoyalBlue),
                        ),
                      ),
                    ),
                ],
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
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
              border: Border.all(color: _kRoyalBlue.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: _kRoyalBlue.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text('지도 터치로 출발/도착 지정', style: TextStyle(color: _kRoyalBlue.withValues(alpha: 0.8), fontSize: 14)),
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
                    foregroundColor: _kRoyalBlue,
                    side: const BorderSide(color: _kRoyalBlue),
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
                    foregroundColor: _kRoyalBlue,
                    side: const BorderSide(color: _kRoyalBlue),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
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
          Expanded(child: Text(value, style: const TextStyle(color: _kRoyalBlue))),
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
          child: OutlinedButton(
            onPressed: canProceed ? _goNext : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kRoyalBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              side: BorderSide(color: canProceed ? _kRoyalBlue : Colors.grey.shade400, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(isLast ? context.l10n('apply_final') : context.l10n('next_step')),
          ),
        ),
      ),
    );
  }
}
