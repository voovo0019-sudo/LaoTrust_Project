// =============================================================================
// wizard_step2_repair.dart
// Step2: 가전수리 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Repair extends StatelessWidget {
  final String repairBrand;
  final Set<String> step2Selections;
  final TextEditingController symptomMemoController;
  final String currentLangCode;
  final void Function(String) onBrandChanged;
  final void Function(String, bool) onSymptomToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Repair({
    super.key,
    required this.repairBrand,
    required this.step2Selections,
    required this.symptomMemoController,
    required this.currentLangCode,
    required this.onBrandChanged,
    required this.onSymptomToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  static const _symptomsByAppliance = <String, List<(String, String)>>{
    'ac': [
      ('symptom_ac_no_cold_air', 'symptom_ac_no_cold_air'),
      ('symptom_ac_noise', 'symptom_ac_noise'),
      ('symptom_ac_water_sound', 'symptom_ac_water_sound'),
      ('symptom_ac_not_cool', 'symptom_ac_not_cool'),
      ('symptom_other', 'symptom_other'),
    ],
    'fridge': [
      ('symptom_fridge_no_cool', 'symptom_fridge_no_cool'),
      ('symptom_fridge_noise', 'symptom_fridge_noise'),
      ('symptom_fridge_door', 'symptom_fridge_door'),
      ('symptom_fridge_ice', 'symptom_fridge_ice'),
      ('symptom_other', 'symptom_other'),
    ],
    'washer': [
      ('symptom_washer_no_spin', 'symptom_washer_no_spin'),
      ('symptom_washer_water_leak', 'symptom_washer_water_leak'),
      ('symptom_washer_noise', 'symptom_washer_noise'),
      ('symptom_washer_no_power', 'symptom_washer_no_power'),
      ('symptom_other', 'symptom_other'),
    ],
    'tv': [
      ('symptom_tv_no_display', 'symptom_tv_no_display'),
      ('symptom_tv_no_sound', 'symptom_tv_no_sound'),
      ('symptom_tv_no_power', 'symptom_tv_no_power'),
      ('symptom_tv_remote', 'symptom_tv_remote'),
      ('symptom_other', 'symptom_other'),
    ],
    'water_purifier': [
      ('symptom_wp_water_leak', 'symptom_wp_water_leak'),
      ('symptom_wp_no_cold', 'symptom_wp_no_cold'),
      ('symptom_wp_no_hot', 'symptom_wp_no_hot'),
      ('symptom_wp_filter', 'symptom_wp_filter'),
      ('symptom_other', 'symptom_other'),
    ],
    'fan': [
      ('symptom_fan_no_spin', 'symptom_fan_no_spin'),
      ('symptom_fan_noise', 'symptom_fan_noise'),
      ('symptom_fan_no_power', 'symptom_fan_no_power'),
      ('symptom_other', 'symptom_other'),
    ],
    'rice_cooker': [
      ('symptom_rc_no_cook', 'symptom_rc_no_cook'),
      ('symptom_rc_no_heat', 'symptom_rc_no_heat'),
      ('symptom_rc_no_power', 'symptom_rc_no_power'),
      ('symptom_other', 'symptom_other'),
    ],
    'generator': [
      ('symptom_gen_no_start', 'symptom_gen_no_start'),
      ('symptom_gen_no_power', 'symptom_gen_no_power'),
      ('symptom_gen_noise', 'symptom_gen_noise'),
      ('symptom_gen_fuel_leak', 'symptom_gen_fuel_leak'),
      ('symptom_other', 'symptom_other'),
    ],
    'water_pump': [
      ('symptom_wp_no_water', 'symptom_wp_no_water'),
      ('symptom_wp_low_pressure', 'symptom_wp_low_pressure'),
      ('symptom_wp_noise', 'symptom_wp_noise'),
      ('symptom_wp_no_start', 'symptom_wp_no_start'),
      ('symptom_other', 'symptom_other'),
    ],
    'solar_panel': [
      ('symptom_sp_no_charge', 'symptom_sp_no_charge'),
      ('symptom_sp_low_output', 'symptom_sp_low_output'),
      ('symptom_sp_panel_damage', 'symptom_sp_panel_damage'),
      ('symptom_other', 'symptom_other'),
    ],
    'other': [
      ('symptom_other_broken', 'symptom_other_broken'),
      ('symptom_other_noise', 'symptom_other_noise'),
      ('symptom_other_no_power', 'symptom_other_no_power'),
      ('symptom_other', 'symptom_other'),
    ],
  };

  static const _applianceEmojis = <String, String>{
    'ac': '❄️',
    'fridge': '🧊',
    'washer': '🫧',
    'tv': '📺',
    'water_purifier': '💧',
    'fan': '🌀',
    'rice_cooker': '🍚',
    'generator': '⚡',
    'water_pump': '💧',
    'solar_panel': '☀️',
    'other': '🔧',
  };

  static const _applianceKeys = <String, String>{
    'ac': 'appliance_ac',
    'fridge': 'appliance_fridge',
    'washer': 'appliance_washer',
    'tv': 'appliance_tv',
    'water_purifier': 'appliance_water_purifier',
    'fan': 'appliance_fan',
    'rice_cooker': 'appliance_rice_cooker',
    'generator': 'appliance_generator',
    'water_pump': 'appliance_water_pump',
    'solar_panel': 'appliance_solar_panel',
    'other': 'appliance_other',
  };

  @override
  Widget build(BuildContext context) {
    final symptoms = _symptomsByAppliance[repairBrand] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('appliance_select_title'),
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kWizardRoyalBlue),
        ),
        const SizedBox(height: 6),
        Text(
          _t('appliance_select_desc'),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: _applianceKeys.entries.map((entry) {
            final id = entry.key;
            final labelKey = entry.value;
            final emoji = _applianceEmojis[id] ?? '🔧';
            final selected = repairBrand == id;
            return GestureDetector(
              onTap: () => onBrandChanged(selected ? '' : id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? kWizardRoyalBlue.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? kWizardRoyalBlue
                        : Colors.grey.shade300,
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: kWizardRoyalBlue.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text(
                      _t(labelKey),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? kWizardRoyalBlue
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: repairBrand.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: kWizardRoyalBlue,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _applianceEmojis[repairBrand] ?? '🔧',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _t(_applianceKeys[repairBrand] ??
                                'appliance_other'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t('request_step1_title'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kWizardRoyalBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t('request_step1_desc'),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    ...symptoms.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: wizardOutlineToggleTile(
                            label: _t(e.$2),
                            selected: step2Selections.contains(e.$1),
                            onTap: () =>
                                onSymptomToggled(e.$1,
                                    step2Selections.contains(e.$1)),
                          ),
                        )),
                    const SizedBox(height: 16),
                    TextField(
                      controller: symptomMemoController,
                      onChanged: (_) => onStateChanged(),
                      decoration: wizardOutlineFieldDecoration(
                        _t('repair_other_label'),
                        hint: _t('repair_other_hint'),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class WizardStep2Electric extends StatelessWidget {
  final Set<String> step2Selections;
  final TextEditingController otherController;
  final String currentLangCode;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Electric({
    super.key,
    required this.step2Selections,
    required this.otherController,
    required this.currentLangCode,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  @override
  Widget build(BuildContext context) {
    const types = [
      ('outlet', 'symptom_elec_outlet'),
      ('lighting', 'symptom_elec_lighting'),
      ('breaker', 'symptom_elec_breaker'),
      ('aircon', 'symptom_elec_aircon'),
      ('intercom', 'symptom_elec_intercom'),
      ('other', 'symptom_other'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('service_electric'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 12),
        ...types.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: step2Selections.contains(e.$1),
                onTap: () => onSelectionToggled(
                    e.$1, step2Selections.contains(e.$1)),
              ),
            )),
        const SizedBox(height: 12),
        TextField(
          controller: otherController,
          onChanged: (_) => onStateChanged(),
          decoration: wizardOutlineFieldDecoration(
            _t('repair_other_label'),
            hint: _t('repair_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

class WizardStep2Plumbing extends StatelessWidget {
  final Set<String> step2Selections;
  final TextEditingController otherController;
  final String currentLangCode;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Plumbing({
    super.key,
    required this.step2Selections,
    required this.otherController,
    required this.currentLangCode,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  @override
  Widget build(BuildContext context) {
    const types = [
      ('leak', 'symptom_plumb_leak'),
      ('toilet', 'symptom_plumb_toilet'),
      ('sink', 'symptom_plumb_sink'),
      ('water_heater', 'symptom_plumb_water_heater'),
      ('drain', 'symptom_plumb_drain'),
      ('other', 'symptom_other'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('service_plumbing'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 12),
        ...types.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: step2Selections.contains(e.$1),
                onTap: () => onSelectionToggled(
                    e.$1, step2Selections.contains(e.$1)),
              ),
            )),
        const SizedBox(height: 12),
        TextField(
          controller: otherController,
          onChanged: (_) => onStateChanged(),
          decoration: wizardOutlineFieldDecoration(
            _t('repair_other_label'),
            hint: _t('repair_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

class WizardStep2RoofPaint extends StatelessWidget {
  final Set<String> step2Selections;
  final TextEditingController otherController;
  final String currentLangCode;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2RoofPaint({
    super.key,
    required this.step2Selections,
    required this.otherController,
    required this.currentLangCode,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  @override
  Widget build(BuildContext context) {
    const types = [
      ('interior', 'symptom_roof_interior'),
      ('exterior', 'symptom_roof_exterior'),
      ('leak', 'symptom_roof_leak'),
      ('replace', 'symptom_roof_replace'),
      ('waterproof', 'symptom_roof_waterproof'),
      ('other', 'symptom_other'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('wizard_repair_sub_roof_paint'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 12),
        ...types.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: step2Selections.contains(e.$1),
                onTap: () => onSelectionToggled(
                    e.$1, step2Selections.contains(e.$1)),
              ),
            )),
        const SizedBox(height: 12),
        TextField(
          controller: otherController,
          onChanged: (_) => onStateChanged(),
          decoration: wizardOutlineFieldDecoration(
            _t('repair_other_label'),
            hint: _t('repair_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
