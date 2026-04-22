// =============================================================================
// wizard_step2_interior.dart
// Step2: 인테리어 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Interior extends StatelessWidget {
  final String subTypeId;
  final Set<String> interiorParts;
  final Set<String> step2Selections;
  final TextEditingController budgetController;
  final TextEditingController otherController;
  final TextEditingController step1OtherController;
  final String currentLangCode;
  final void Function(String, bool) onInteriorPartToggled;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Interior({
    super.key,
    required this.subTypeId,
    required this.interiorParts,
    required this.step2Selections,
    required this.budgetController,
    required this.otherController,
    required this.step1OtherController,
    required this.currentLangCode,
    required this.onInteriorPartToggled,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _areaField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('interior_area_label'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: wizardOutlineFieldDecoration(
              _t('interior_area_label'),
              hint: _t('interior_area_hint'),
            ),
          ),
        ],
      );

  Widget _otherField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(_t('wizard_other_service_label'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          TextField(
            controller: otherController,
            decoration: wizardOutlineFieldDecoration(
              _t('wizard_other_service_label'),
              hint: _t('wizard_other_service_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );

  Widget _housingTypeRow() {
    final types = [
      ('house', _t('interior_housing_house')),
      ('apartment', _t('interior_housing_apartment')),
      ('condo', _t('interior_housing_condo')),
      ('commercial', _t('interior_housing_commercial')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('interior_housing_type'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((e) {
            final selected = interiorParts.contains(e.$1);
            return wizardOutlineToggleTile(
              label: e.$2,
              selected: selected,
              onTap: () => onInteriorPartToggled(e.$1, selected),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (subTypeId) {
      case 'wallpaper':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _housingTypeRow(),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('interior_wallpaper_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('paper', _t('interior_wallpaper_paper')),
                ('fabric', _t('interior_wallpaper_fabric')),
                ('paint', _t('interior_wallpaper_paint')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _otherField(),
          ],
        );

      case 'flooring':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _housingTypeRow(),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('interior_floor_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('tile', _t('interior_floor_tile')),
                ('wood', _t('interior_floor_wood')),
                ('marble', _t('interior_floor_marble')),
                ('vinyl', _t('interior_floor_vinyl')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _otherField(),
          ],
        );

      case 'painting':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _housingTypeRow(),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('interior_painting_area'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('interior', _t('interior_painting_interior')),
                ('exterior', _t('interior_painting_exterior')),
                ('both', _t('interior_painting_both')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _otherField(),
          ],
        );

      case 'bathroom':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('interior_bathroom_scope'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('tile', _t('interior_bathroom_tile')),
                ('toilet', _t('interior_bathroom_toilet')),
                ('sink', _t('interior_bathroom_sink')),
                ('shower', _t('interior_bathroom_shower')),
                ('full', _t('interior_bathroom_full')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _otherField(),
          ],
        );

      case 'kitchen':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('interior_kitchen_scope'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('cabinet', _t('interior_kitchen_cabinet')),
                ('countertop', _t('interior_kitchen_countertop')),
                ('sink', _t('interior_kitchen_sink')),
                ('full', _t('interior_kitchen_full')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _otherField(),
          ],
        );

      case 'remodel':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _housingTypeRow(),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('interior_remodel_scope'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('partial', _t('interior_remodel_partial')),
                ('full', _t('interior_remodel_full')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_t('interior_budget_label'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('budget_s', _t('interior_budget_s')),
                ('budget_m', _t('interior_budget_m')),
                ('budget_l', _t('interior_budget_l')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _otherField(),
          ],
        );

      default:
        return TextField(
          controller: step1OtherController,
          decoration: wizardOutlineFieldDecoration(
            _t('wizard_other_service_name_label'),
            hint: _t('wizard_other_service_name_hint'),
          ),
          maxLines: 3,
        );
    }
  }
}
