// =============================================================================
// wizard_step2_tutoring.dart
// Step2: 과외·레슨 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Tutoring extends StatelessWidget {
  final String subTypeId;
  final Set<String> tutoringLevels;
  final Set<String> step2Selections;
  final TextEditingController goalController;
  final String currentLangCode;
  final void Function(String, bool) onLevelToggled;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;
  final Set<String> fieldErrors;

  const WizardStep2Tutoring({
    super.key,
    required this.subTypeId,
    required this.tutoringLevels,
    required this.step2Selections,
    required this.goalController,
    required this.currentLangCode,
    required this.onLevelToggled,
    required this.onSelectionToggled,
    required this.onStateChanged,
    required this.fieldErrors,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _goalField() => TextField(
        controller: goalController,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('tutor_goal_label'),
          hint: _t('tutor_goal_hint'),
          isRequired: true,
          hasError: fieldErrors.contains('tutoringLevel'),
          errorText: _t('wizard_field_required'),
        ),
        maxLines: 2,
      );

  Widget _classTypeRow() {
    const types = [
      ('online', 'tutor_class_online'),
      ('visit', 'tutor_class_visit'),
      ('center', 'tutor_class_center'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('tutor_class_type_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((e) {
            final selected = step2Selections.contains(e.$1);
            return wizardOutlineToggleTile(
              label: _t(e.$2),
              selected: selected,
              onTap: () => onSelectionToggled(e.$1, selected),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _levelRow() {
    const levels = [
      ('elem', 'wizard_level_elem'),
      ('mid', 'wizard_level_mid'),
      ('high', 'wizard_level_high'),
      ('adult', 'wizard_level_adult'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('wizard_tutoring_level_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((e) {
            final selected = tutoringLevels.contains(e.$1);
            return wizardOutlineToggleTile(
              label: _t(e.$2),
              selected: selected,
              onTap: () => onLevelToggled(e.$1, selected),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _experienceRow() {
    const levels = [
      ('beginner', 'tutor_exp_beginner'),
      ('intermediate', 'tutor_exp_intermediate'),
      ('advanced', 'tutor_exp_advanced'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('tutor_exp_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((e) {
            final selected = tutoringLevels.contains(e.$1);
            return wizardOutlineToggleTile(
              label: _t(e.$2),
              selected: selected,
              onTap: () => onLevelToggled(e.$1, selected),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (subTypeId == 'lang_en' || subTypeId == 'lang_ko' ||
        subTypeId == 'lang_lo' || subTypeId == 'lang_zh') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _levelRow(),
          const SizedBox(height: 16),
          _classTypeRow(),
          const SizedBox(height: 16),
          _goalField(),
        ],
      );
    }

    if (subTypeId == 'math_science') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _levelRow(),
          const SizedBox(height: 16),
          _classTypeRow(),
          const SizedBox(height: 16),
          _goalField(),
        ],
      );
    }

    if (subTypeId == 'music' || subTypeId == 'martial_arts' ||
        subTypeId == 'cooking' || subTypeId == 'computer' ||
        subTypeId == 'art') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _experienceRow(),
          const SizedBox(height: 16),
          _classTypeRow(),
          const SizedBox(height: 16),
          _goalField(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _classTypeRow(),
        const SizedBox(height: 16),
        _goalField(),
      ],
    );
  }
}
