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
      ('beauty_dur_60min', 'beauty_duration_60'),
      ('beauty_dur_90min', 'beauty_duration_90'),
      ('beauty_dur_120min', 'beauty_duration_120'),
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
                selected: step2Selections.contains('beauty_visit_home'),
                onTap: () => onVisitTypeSelected('beauty_visit_home'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: wizardOutlineToggleTile(
                label: _t('beauty_visit_shop'),
                selected: step2Selections.contains('beauty_visit_shop'),
                onTap: () => onVisitTypeSelected('beauty_visit_shop'),
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
          Text(
            _t('beauty_body_part_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('beauty_body_full', 'beauty_body_full'),
              ('beauty_body_back', 'beauty_body_back'),
              ('beauty_body_leg', 'beauty_body_leg'),
              ('beauty_body_head', 'beauty_body_head'),
            ].map((e) {
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    if (subTypeId == 'massage_aroma') {
      const aromaTypes = [
        ('beauty_aroma_swedish', 'beauty_aroma_swedish'),
        ('beauty_aroma_deep_tissue', 'beauty_aroma_deep_tissue'),
        ('beauty_aroma_hot_stone', 'beauty_aroma_hot_stone'),
        ('beauty_aroma_foot', 'beauty_aroma_foot'),
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    if (subTypeId == 'nail') {
      const nailTypes = [
        ('beauty_nail_gel', 'beauty_nail_gel'),
        ('beauty_nail_acrylic', 'beauty_nail_acrylic'),
        ('beauty_nail_art', 'beauty_nail_art'),
        ('beauty_nail_removal', 'beauty_nail_removal'),
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    if (subTypeId == 'hair') {
      const hairTypes = [
        ('beauty_hair_cut', 'beauty_hair_cut'),
        ('beauty_hair_perm', 'beauty_hair_perm'),
        ('beauty_hair_color', 'beauty_hair_color'),
        ('beauty_hair_treatment', 'beauty_hair_treatment'),
        ('beauty_hair_styling', 'beauty_hair_styling'),
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    if (subTypeId == 'makeup') {
      const makeupTypes = [
        ('beauty_makeup_wedding', 'beauty_makeup_wedding'),
        ('beauty_makeup_event', 'beauty_makeup_event'),
        ('beauty_makeup_daily', 'beauty_makeup_daily'),
        ('beauty_makeup_photo', 'beauty_makeup_photo'),
        ('beauty_makeup_baci', 'beauty_makeup_baci'),
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    if (subTypeId == 'waxing') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('beauty_waxing_area_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('beauty_waxing_arms_legs', 'beauty_waxing_arms_legs'),
              ('beauty_waxing_bikini', 'beauty_waxing_bikini'),
              ('beauty_waxing_underarm', 'beauty_waxing_underarm'),
              ('face', 'beauty_waxing_face'),
              ('full', 'beauty_waxing_full'),
            ].map((e) {
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    if (subTypeId == 'skin_care') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('beauty_skin_type_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('basic', 'beauty_skin_basic'),
              ('deep', 'beauty_skin_deep'),
              ('moisture', 'beauty_skin_moisture'),
              ('whitening', 'beauty_skin_whitening'),
              ('antiaging', 'beauty_skin_antiaging'),
              ('acne', 'beauty_skin_acne'),
            ].map((e) {
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
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('beauty_other_label'),
              hint: _t('beauty_other_hint'),
            ),
            maxLines: 2,
          ),
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
