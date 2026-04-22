// =============================================================================
// wizard_step2_beauty.dart
// Step2: 미용·웰빙 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Beauty extends StatelessWidget {
  final String subTypeId;
  final Set<String> step2Selections;
  final TextEditingController peopleController;
  final TextEditingController otherController;
  final String currentLangCode;
  final void Function(String, bool) onSelectionToggled;
  final void Function(String) onVisitTypeSelected;
  final VoidCallback onStateChanged;
  final Set<String> fieldErrors;

  const WizardStep2Beauty({
    super.key,
    required this.subTypeId,
    required this.step2Selections,
    required this.peopleController,
    required this.otherController,
    required this.currentLangCode,
    required this.onSelectionToggled,
    required this.onVisitTypeSelected,
    required this.onStateChanged,
    required this.fieldErrors,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _peopleField() => TextField(
        controller: peopleController,
        keyboardType: TextInputType.number,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('beauty_people_label'),
          hint: _t('beauty_people_hint'),
          isRequired: true,
          hasError: fieldErrors.contains('beautyPeople'),
          errorText: _t('wizard_field_required'),
        ),
      );

  Widget _massageDurationRow() {
    const durations = [
      ('60min', 'beauty_duration_60'),
      ('90min', 'beauty_duration_90'),
      ('120min', 'beauty_duration_120'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('beauty_duration_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: durations.map((e) {
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

  Widget _visitTypeRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('beauty_visit_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: wizardOutlineToggleTile(
                label: _t('beauty_visit_home'),
                selected: step2Selections.contains('visit_home'),
                onTap: () => onVisitTypeSelected('visit_home'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: wizardOutlineToggleTile(
                label: _t('beauty_visit_shop'),
                selected: step2Selections.contains('visit_shop'),
                onTap: () => onVisitTypeSelected('visit_shop'),
              ),
            ),
          ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (subTypeId == 'massage_traditional') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _massageDurationRow(),
          const SizedBox(height: 16),
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    if (subTypeId == 'massage_aroma') {
      const aromaTypes = [
        ('swedish', 'beauty_aroma_swedish'),
        ('deep_tissue', 'beauty_aroma_deep_tissue'),
        ('hot_stone', 'beauty_aroma_hot_stone'),
        ('foot', 'beauty_aroma_foot'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('beauty_aroma_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aromaTypes.map((e) {
              final selected = step2Selections.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSelectionToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _massageDurationRow(),
          const SizedBox(height: 16),
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    if (subTypeId == 'nail') {
      const nailTypes = [
        ('gel', 'beauty_nail_gel'),
        ('acrylic', 'beauty_nail_acrylic'),
        ('art', 'beauty_nail_art'),
        ('removal', 'beauty_nail_removal'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('beauty_nail_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nailTypes.map((e) {
              final selected = step2Selections.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSelectionToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    if (subTypeId == 'hair') {
      const hairTypes = [
        ('cut', 'beauty_hair_cut'),
        ('perm', 'beauty_hair_perm'),
        ('color', 'beauty_hair_color'),
        ('treatment', 'beauty_hair_treatment'),
        ('styling', 'beauty_hair_styling'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('beauty_hair_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hairTypes.map((e) {
              final selected = step2Selections.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSelectionToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    if (subTypeId == 'makeup') {
      const makeupTypes = [
        ('wedding', 'beauty_makeup_wedding'),
        ('event', 'beauty_makeup_event'),
        ('daily', 'beauty_makeup_daily'),
        ('photo', 'beauty_makeup_photo'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('beauty_makeup_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: makeupTypes.map((e) {
              final selected = step2Selections.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSelectionToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    if (subTypeId == 'waxing') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    if (subTypeId == 'skin_care') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _visitTypeRow(),
          const SizedBox(height: 16),
          _peopleField(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _visitTypeRow(),
        const SizedBox(height: 16),
        _peopleField(),
        const SizedBox(height: 16),
        TextField(
          controller: otherController,
          onChanged: (_) => onStateChanged(),
          decoration: wizardOutlineFieldDecoration(
            _t('wizard_other_service_label'),
            hint: _t('wizard_beauty_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
