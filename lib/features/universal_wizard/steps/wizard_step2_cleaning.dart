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
  final String guesthouseSelectedArea;
  final String guesthouseSelectedScale;
  final String guesthouseSelectedFrequency;
  final void Function(String) onGuesthouseAreaChanged;
  final void Function(String) onGuesthouseScaleChanged;
  final void Function(String) onGuesthouseFrequencyChanged;
  final void Function(String) onBeddingTypeChanged;
  final void Function(String) onApplianceCountChanged;
  final void Function(String, bool) onApplianceTypeToggled;
  final VoidCallback onStateChanged;
  final Set<String> fieldErrors;

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
    required this.guesthouseSelectedArea,
    required this.guesthouseSelectedScale,
    required this.guesthouseSelectedFrequency,
    required this.onGuesthouseAreaChanged,
    required this.onGuesthouseScaleChanged,
    required this.onGuesthouseFrequencyChanged,
    required this.onBeddingTypeChanged,
    required this.onApplianceCountChanged,
    required this.onApplianceTypeToggled,
    required this.onStateChanged,
    required this.fieldErrors,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _areaField() => TextField(
        controller: areaController,
        keyboardType: TextInputType.number,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('cleaning_area_m2'),
          hint: _t('cleaning_area_hint'),
          isRequired: true,
          hasError: fieldErrors.contains('cleaningArea'),
          errorText: _t('wizard_field_required'),
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

  Widget _guesthouseChipSection({
    required String titleKey,
    required List<String> optionKeys,
    required String selectedKey,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(titleKey),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kWizardRoyalBlue,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: optionKeys.map((k) {
            final selected = selectedKey == k;
            return wizardOutlineToggleTile(
              label: _t(k),
              selected: selected,
              onTap: () => onChanged(selected ? '' : k),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _otherMemoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: otherController,
          onChanged: (_) => onStateChanged(),
          decoration: wizardOutlineFieldDecoration(
            _t('cleaning_other_label'),
            hint: _t('cleaning_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

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
            _otherMemoField(),
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
            _otherMemoField(),
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
            _otherMemoField(),
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
                ('cleaning_target_home', _t('cleaning_target_home')),
                ('cleaning_target_office', _t('cleaning_target_office')),
                ('cleaning_target_store', _t('cleaning_target_store')),
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
                ('cleaning_cycle_w1', _t('cleaning_cycle_w1')),
                ('cleaning_cycle_w2', _t('cleaning_cycle_w2')),
                ('cleaning_cycle_m2', _t('cleaning_cycle_m2')),
                ('cleaning_cycle_m1', _t('cleaning_cycle_m1')),
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
            _otherMemoField(),
          ],
        );

      case 'guesthouse':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _guesthouseChipSection(
              titleKey: 'cleaning_area_label',
              optionKeys: const [
                'area_under10',
                'area_10to20',
                'area_20to30',
                'area_over30',
              ],
              selectedKey: guesthouseSelectedArea,
              onChanged: onGuesthouseAreaChanged,
            ),
            const SizedBox(height: 16),
            _guesthouseChipSection(
              titleKey: 'cleaning_scale_label',
              optionKeys: const [
                'cleaning_gh_scale_small',
                'cleaning_gh_scale_medium',
                'cleaning_gh_scale_large',
              ],
              selectedKey: guesthouseSelectedScale,
              onChanged: onGuesthouseScaleChanged,
            ),
            const SizedBox(height: 16),
            _guesthouseChipSection(
              titleKey: 'cleaning_frequency_label',
              optionKeys: const [
                'freq_daily',
                'freq_2to3week',
                'freq_weekly',
                'freq_biweekly',
              ],
              selectedKey: guesthouseSelectedFrequency,
              onChanged: onGuesthouseFrequencyChanged,
            ),
            _otherMemoField(),
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
                ('cleaning_bedding_duvet', _t('cleaning_bedding_duvet')),
                ('cleaning_bedding_pillow', _t('cleaning_bedding_pillow')),
                ('cleaning_bedding_mattress', _t('cleaning_bedding_mattress')),
                ('cleaning_bedding_set', _t('cleaning_bedding_set')),
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
            _otherMemoField(),
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
                ('cleaning_appliance_ac', _t('cleaning_appliance_ac')),
                ('cleaning_appliance_fridge', _t('cleaning_appliance_fridge')),
                ('cleaning_appliance_washer', _t('cleaning_appliance_washer')),
                ('cleaning_appliance_dishwasher', _t('cleaning_appliance_dishwasher')),
                ('cleaning_appliance_oven', _t('cleaning_appliance_oven')),
                ('cleaning_appliance_microwave', _t('cleaning_appliance_microwave')),
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
            _otherMemoField(),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: otherController,
              onChanged: (_) => onStateChanged(),
              decoration: wizardOutlineFieldDecoration(
                _t('cleaning_other_label'),
                hint: _t('cleaning_other_hint'),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _areaField(),
          ],
        );
    }
  }
}
