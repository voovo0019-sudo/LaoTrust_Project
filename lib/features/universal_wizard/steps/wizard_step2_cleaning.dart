// =============================================================================
// wizard_step2_cleaning.dart
// Step2: 청소 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Cleaning extends StatelessWidget {
  final String subTypeId;
  final String cleaningScale;
  final String cleaningHouseType;
  final String cleaningRoomCount;
  final String cleaningBathroomCount;
  final String cleaningVisitCycle;
  final String cleaningBeddingType;
  final String cleaningApplianceCount;
  final Set<String> cleaningApplianceTypes;
  final TextEditingController areaController;
  final TextEditingController targetController;
  final TextEditingController industryController;
  final TextEditingController beddingCountController;
  final TextEditingController otherController;
  final Set<String> step2Selections;
  final String currentLangCode;
  final void Function(String) onScaleChanged;
  final void Function(String) onHouseTypeChanged;
  final void Function(String) onRoomCountChanged;
  final void Function(String) onBathroomCountChanged;
  final void Function(String) onVisitCycleChanged;
  final void Function(String) onBeddingTypeChanged;
  final void Function(String) onApplianceCountChanged;
  final void Function(String, bool) onApplianceTypeToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Cleaning({
    super.key,
    required this.subTypeId,
    required this.cleaningScale,
    required this.cleaningHouseType,
    required this.cleaningRoomCount,
    required this.cleaningBathroomCount,
    required this.cleaningVisitCycle,
    required this.cleaningBeddingType,
    required this.cleaningApplianceCount,
    required this.cleaningApplianceTypes,
    required this.areaController,
    required this.targetController,
    required this.industryController,
    required this.beddingCountController,
    required this.otherController,
    required this.step2Selections,
    required this.currentLangCode,
    required this.onScaleChanged,
    required this.onHouseTypeChanged,
    required this.onRoomCountChanged,
    required this.onBathroomCountChanged,
    required this.onVisitCycleChanged,
    required this.onBeddingTypeChanged,
    required this.onApplianceCountChanged,
    required this.onApplianceTypeToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _areaField() => TextField(
        controller: areaController,
        keyboardType: TextInputType.number,
        decoration: wizardOutlineFieldDecoration(
          _t('cleaning_area_m2'),
          hint: _t('cleaning_area_hint'),
        ),
      );

  Widget _scaleRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('wizard_cleaning_scale_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final s in ['S', 'M', 'L'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: wizardOutlineToggleTile(
                      label: _t('cleaning_size_${s.toLowerCase()}'),
                      selected: cleaningScale == s,
                      onTap: () => onScaleChanged(cleaningScale == s ? '' : s),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _housingTypeRow() {
    final types = [
      ('apartment', _t('cleaning_house_apartment')),
      ('villa', _t('cleaning_house_villa')),
      ('detached', _t('cleaning_house_detached')),
      ('officetel', _t('cleaning_house_officetel')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('cleaning_house_type'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((e) {
            final selected = cleaningHouseType == e.$1;
            return wizardOutlineToggleTile(
              label: e.$2,
              selected: selected,
              onTap: () =>
                  onHouseTypeChanged(selected ? '' : e.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (subTypeId) {
      case 'move_in':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _housingTypeRow(),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            Text(_t('cleaning_room_count'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Row(children: [
              for (final n in ['1', '2', '3', '4+'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: wizardOutlineToggleTile(
                      label: n,
                      selected: cleaningRoomCount == n,
                      onTap: () => onRoomCountChanged(
                          cleaningRoomCount == n ? '' : n),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            Text(_t('cleaning_bathroom_count'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Row(children: [
              for (final n in ['1', '2', '3+'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: wizardOutlineToggleTile(
                      label: n,
                      selected: cleaningBathroomCount == n,
                      onTap: () => onBathroomCountChanged(
                          cleaningBathroomCount == n ? '' : n),
                    ),
                  ),
                ),
            ]),
          ],
        );

      case 'house_cleaning':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _housingTypeRow(),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            _scaleRow(),
          ],
        );

      case 'restaurant_cafe':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: industryController,
              decoration: wizardOutlineFieldDecoration(
                _t('wizard_cleaning_restaurant_label'),
                hint: _t('wizard_cleaning_restaurant_hint'),
              ),
            ),
            const SizedBox(height: 12),
            _areaField(),
            const SizedBox(height: 12),
            _scaleRow(),
          ],
        );

      case 'regular_visit':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('cleaning_visit_target'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('home', _t('cleaning_visit_home')),
                ('office', _t('cleaning_visit_office')),
                ('store', _t('cleaning_visit_store')),
              ].map((e) {
                final selected = targetController.text == e.$1;
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () {
                    targetController.text = selected ? '' : e.$1;
                    onStateChanged();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_t('cleaning_visit_cycle'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('w1', _t('cleaning_cycle_w1')),
                ('w2', _t('cleaning_cycle_w2')),
                ('m2', _t('cleaning_cycle_m2')),
                ('m1', _t('cleaning_cycle_m1')),
              ].map((e) {
                final selected = cleaningVisitCycle == e.$1;
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () =>
                      onVisitCycleChanged(selected ? '' : e.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _areaField(),
          ],
        );

      case 'bedding':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('cleaning_bedding_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('duvet', _t('cleaning_bedding_duvet')),
                ('pillow', _t('cleaning_bedding_pillow')),
                ('mattress', _t('cleaning_bedding_mattress')),
                ('set', _t('cleaning_bedding_set')),
              ].map((e) {
                final selected = cleaningBeddingType == e.$1;
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () =>
                      onBeddingTypeChanged(selected ? '' : e.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_t('cleaning_appliance_count'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Row(children: [
              for (final n in [
                ('1', _t('cleaning_count_1')),
                ('2', _t('cleaning_count_2')),
                ('3+', _t('cleaning_count_3plus')),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: wizardOutlineToggleTile(
                      label: n.$2,
                      selected: beddingCountController.text == n.$1,
                      onTap: () {
                        beddingCountController.text =
                            beddingCountController.text == n.$1
                                ? ''
                                : n.$1;
                        onStateChanged();
                      },
                    ),
                  ),
                ),
            ]),
          ],
        );

      case 'appliance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('cleaning_appliance_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('ac', _t('cleaning_appliance_ac')),
                ('fridge', _t('cleaning_appliance_fridge')),
                ('washer', _t('cleaning_appliance_washer')),
                ('dishwasher', _t('cleaning_appliance_dishwasher')),
                ('oven', _t('cleaning_appliance_oven')),
                ('microwave', _t('cleaning_appliance_microwave')),
              ].map((e) {
                final selected = cleaningApplianceTypes.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onApplianceTypeToggled(e.$1, selected),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_t('cleaning_appliance_count'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Row(children: [
              for (final n in [
                ('1', _t('cleaning_count_1')),
                ('2', _t('cleaning_count_2')),
                ('3+', _t('cleaning_count_3plus')),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: wizardOutlineToggleTile(
                      label: n.$2,
                      selected: cleaningApplianceCount == n.$1,
                      onTap: () => onApplianceCountChanged(
                          cleaningApplianceCount == n.$1 ? '' : n.$1),
                    ),
                  ),
                ),
            ]),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: otherController,
              decoration: wizardOutlineFieldDecoration(
                _t('wizard_other_service_label'),
                hint: _t('wizard_other_service_hint'),
              ),
            ),
            const SizedBox(height: 12),
            _areaField(),
          ],
        );
    }
  }
}
