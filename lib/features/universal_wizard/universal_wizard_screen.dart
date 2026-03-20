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
        return context.l10n('wizard_photo_prompt_repair');
      case 'expert_delivery':
        return context.l10n('wizard_photo_prompt_delivery');
      case 'expert_beauty':
        return context.l10n('wizard_photo_prompt_style_concept');
      case 'expert_photo':
        return context.l10n('wizard_photo_prompt_style_concept');
      case 'expert_cleaning':
        return context.l10n('wizard_photo_prompt_cleaning');
      case 'expert_tutoring':
        return context.l10n('wizard_photo_prompt_tutoring');
      case 'expert_security':
        return context.l10n('wizard_photo_prompt_security');
      case 'expert_garden':
        return context.l10n('wizard_photo_prompt_garden');
      case 'expert_event':
        return context.l10n('wizard_photo_prompt_event');
      default:
        return context.l10n('wizard_photo_prompt_generic');
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
            context
                .l10n('wizard_step_progress')
                .replaceAll('{current}', '${_currentStep + 1}')
                .replaceAll('{total}', '$totalSteps'),
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
          Text(
            context.l10n('wizard_step1_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 20),
          ...config.step1SubTypes.map((e) {
            final selected = _state.step1SubTypeId == e.key;
            final label = context.l10n(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    if (selected) {
                      _state = _state.copyWith(step1SubTypeId: '', step1SubTypeLabel: '');
                      return;
                    }
                    _state = _state.copyWith(step1SubTypeId: e.key, step1SubTypeLabel: e.value);
                  }),
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
          Text(
            context.l10n('wizard_step2_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
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
      'ac' => ['symptom_ac_no_cold_air', 'symptom_ac_noise', 'wizard_symptom_ac_water_drop', 'symptom_ac_not_cool'],
      'household' => ['symptom_household_power', 'symptom_household_noise', 'symptom_household_stopped', 'symptom_household_broken'],
      'electric' => ['symptom_electric_breaker', 'symptom_electric_burn_smell', 'symptom_electric_flicker', 'symptom_electric_leak'],
      'plumbing' => ['symptom_plumbing_leak', 'symptom_plumbing_clog', 'symptom_plumbing_backflow', 'symptom_plumbing_low_pressure'],
      'roof' => ['wizard_symptom_roof_peeling', 'wizard_symptom_roof_leak_proof', 'wizard_symptom_roof_crack_repair'],
      _ => <String>[],
    };
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(o),
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
          label: context.l10n('symptom_other'),
          selected: _step2OtherSelected,
          onTap: () => setState(() {
            _step2OtherSelected = !_step2OtherSelected;
            if (!_step2OtherSelected) _step2OtherController.clear();
          }),
        ),
      ),
      if (_step2OtherSelected)
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_other_direct_input_hint'),
          ),
          maxLines: 2,
        ),
    ];
  }

  List<Widget> _buildStep2Delivery() {
    return [
      TextField(
        controller: _weightKgController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_delivery_weight_label'),
          hint: context.l10n('wizard_delivery_weight_hint'),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _distanceKmController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_delivery_distance_label'),
          hint: context.l10n('wizard_delivery_distance_hint'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n('wizard_delivery_cargo_size_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
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
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_delivery_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Beauty() {
    const options = [
      'wizard_beauty_option_cut',
      'wizard_beauty_option_perm',
      'wizard_beauty_option_care',
      'wizard_beauty_option_nail',
      'wizard_beauty_option_makeup',
    ];
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(o),
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
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_beauty_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Photo() {
    return [
      TextField(
        controller: _photoTimeController,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_photo_time_label'),
          hint: context.l10n('wizard_photo_time_hint'),
        ),
        maxLines: 1,
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n('wizard_photo_place_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: context.l10n('wizard_photo_place_indoor'),
        selected: _photoPlaceSelections.contains('wizard_photo_place_indoor'),
        onTap: () => setState(() {
          if (_photoPlaceSelections.contains('wizard_photo_place_indoor')) {
            _photoPlaceSelections.remove('wizard_photo_place_indoor');
          } else {
            _photoPlaceSelections.add('wizard_photo_place_indoor');
          }
        }),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: context.l10n('wizard_photo_place_outdoor'),
        selected: _photoPlaceSelections.contains('wizard_photo_place_outdoor'),
        onTap: () => setState(() {
          if (_photoPlaceSelections.contains('wizard_photo_place_outdoor')) {
            _photoPlaceSelections.remove('wizard_photo_place_outdoor');
          } else {
            _photoPlaceSelections.add('wizard_photo_place_outdoor');
          }
        }),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_photo_other_hint'),
          ),
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
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_cleaning_area_label'),
          hint: context.l10n('wizard_cleaning_area_hint'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n('wizard_cleaning_scale_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
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
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_cleaning_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Tutoring() {
    const levels = [
      'wizard_level_elem',
      'wizard_level_mid',
      'wizard_level_high',
      'wizard_level_adult',
    ];
    return [
      Text(
        context.l10n('wizard_tutoring_level_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      for (final l in levels) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(l),
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
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_tutoring_other_hint'),
          ),
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
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_security_people_label'),
          hint: context.l10n('wizard_security_people_hint'),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _securityTimeController,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_security_time_label'),
          hint: context.l10n('wizard_security_time_hint'),
        ),
        maxLines: 1,
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_security_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Garden() {
    const scopes = [
      'wizard_garden_scope_lawn',
      'wizard_garden_scope_landscape',
      'wizard_garden_scope_tree_trim',
      'wizard_garden_scope_all',
    ];
    return [
      Text(
        context.l10n('wizard_garden_scale_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
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
      Text(
        context.l10n('wizard_garden_scope_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      for (final s in scopes)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(s),
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
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_garden_other_hint'),
          ),
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
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_event_people_label'),
          hint: context.l10n('wizard_event_people_hint'),
        ),
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_event_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    ];
  }

  List<Widget> _buildStep2GenericMultiSelect() {
    const options = ['wizard_generic_option_1', 'wizard_generic_option_2', 'wizard_generic_option_3'];
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(o),
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
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(context.l10n('wizard_other_direct_input_label')),
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
            context
                .l10n('wizard_photo_upload_max')
                .replaceAll('{n}', '$slots'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImagesFromGallery(maxCount: slots),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.l10n('wizard_photo_pick_gallery')),
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
                  label: Text(context.l10n('wizard_photo_pick_camera')),
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
              labelText: context.l10n('wizard_extra_request_label'),
              hintText: context.l10n('wizard_extra_request_hint'),
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
          Text(
            context.l10n('wizard_map_pick_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n('wizard_map_pick_desc'),
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
                  Text(
                    context.l10n('wizard_map_pick_hint'),
                    style: TextStyle(color: _kRoyalBlue.withValues(alpha: 0.8), fontSize: 14),
                  ),
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
                  label: Text(context.l10n('wizard_origin')),
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
                  label: Text(context.l10n('wizard_destination')),
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
          Text(
            context.l10n('wizard_tutoring_textfields_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _state = _state.copyWith(step3LearningGoal: v)),
            decoration: InputDecoration(
              labelText: context.l10n('wizard_learning_goal_label'),
              hintText: context.l10n('wizard_learning_goal_hint'),
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
              labelText: context.l10n('wizard_schedule_label'),
              hintText: context.l10n('wizard_schedule_hint'),
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
          Text(
            context.l10n('wizard_note_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _state = _state.copyWith(step3ExtraNote: v)),
            decoration: InputDecoration(
              labelText: context.l10n('wizard_extra_request_label'),
              hintText: context.l10n('wizard_extra_request_hint'),
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
          Text(
            context.l10n('wizard_summary_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 20),
          _summaryRow(context.l10n('wizard_summary_category'), context.l10n(config.categoryKey)),
          _summaryRow(
            context.l10n('wizard_summary_subtype'),
            _state.step1SubTypeLabel.isEmpty ? '' : context.l10n(_state.step1SubTypeLabel),
          ),
          if (_state.step2SelectedLabel.isNotEmpty)
            _summaryRow(
              context.l10n('wizard_summary_detail'),
              context.l10n(_state.step2SelectedLabel),
            ),
          if (_state.step3ExtraNote.isNotEmpty)
            _summaryRow(context.l10n('wizard_summary_note'), _state.step3ExtraNote),
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
            child: Text(isLast ? context.t('apply_final') : context.t('next_step')),
          ),
        ),
      ),
    );
  }
}
