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
  final TextEditingController areaController;
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
    required this.areaController,
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
            controller: areaController,
            keyboardType: TextInputType.number,
            decoration: wizardOutlineFieldDecoration(
              _t('interior_area_label'),
              hint: _t('interior_area_hint'),
            ),
          ),
        ],
      );

  Widget _budgetRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            _t('interior_budget_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('interior_budget_s', 'interior_budget_s'),
              ('interior_budget_m', 'interior_budget_m'),
              ('interior_budget_l', 'interior_budget_l'),
            ].map((e) {
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

  Widget _otherField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('interior_other_label'),
              hint: _t('interior_other_hint'),
            ),
            maxLines: 2,
          ),
        ],
      );

  Widget _housingTypeRow() {
    final types = [
      ('interior_housing_house', _t('interior_housing_house')),
      ('interior_housing_apartment', _t('interior_housing_apartment')),
      ('interior_housing_condo', _t('interior_housing_condo')),
      ('interior_housing_commercial', _t('interior_housing_commercial')),
      ('interior_housing_villa', _t('interior_housing_villa')),
      ('interior_housing_townhouse', _t('interior_housing_townhouse')),
      ('interior_housing_guesthouse', _t('interior_housing_guesthouse')),
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
                ('interior_wallpaper_paper', _t('interior_wallpaper_paper')),
                ('interior_wallpaper_fabric', _t('interior_wallpaper_fabric')),
                ('interior_wallpaper_paint', _t('interior_wallpaper_paint')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _budgetRow(),
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
                ('interior_floor_tile', _t('interior_floor_tile')),
                ('interior_floor_wood', _t('interior_floor_wood')),
                ('interior_floor_marble', _t('interior_floor_marble')),
                ('interior_floor_vinyl', _t('interior_floor_vinyl')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _budgetRow(),
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
                ('interior_painting_interior', _t('interior_painting_interior')),
                ('interior_painting_exterior', _t('interior_painting_exterior')),
                ('interior_scope_both', _t('interior_scope_both')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _budgetRow(),
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
                ('interior_bathroom_tile', _t('interior_bathroom_tile')),
                ('interior_bathroom_toilet', _t('interior_bathroom_toilet')),
                ('interior_bathroom_sink', _t('interior_bathroom_sink')),
                ('interior_bathroom_shower', _t('interior_bathroom_shower')),
                ('interior_bathroom_full', _t('interior_bathroom_full')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _budgetRow(),
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
                ('interior_kitchen_cabinet', _t('interior_kitchen_cabinet')),
                ('interior_kitchen_countertop', _t('interior_kitchen_countertop')),
                ('interior_kitchen_sink', _t('interior_kitchen_sink')),
                ('interior_kitchen_full', _t('interior_kitchen_full')),
              ].map((e) {
                final selected = step2Selections.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onSelectionToggled(e.$1, selected),
                );
              }).toList(),
            ),
            _budgetRow(),
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
                ('interior_remodel_partial', _t('interior_remodel_partial')),
                ('interior_remodel_full', _t('interior_remodel_full')),
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
                ('interior_budget_s', _t('interior_budget_s')),
                ('interior_budget_m', _t('interior_budget_m')),
                ('interior_budget_l', _t('interior_budget_l')),
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
