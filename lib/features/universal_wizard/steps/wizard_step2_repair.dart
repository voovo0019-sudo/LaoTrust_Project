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

  const WizardStep2Repair({
    super.key,
    required this.repairBrand,
    required this.step2Selections,
    required this.symptomMemoController,
    required this.currentLangCode,
    required this.onBrandChanged,
    required this.onSymptomToggled,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  static const _symptomsByAppliance = <String, List<(String, String)>>{
    'ac': [
      ('no_cold', 'symptom_ac_no_cold_air'),
      ('noise', 'symptom_ac_noise'),
      ('water_leak', 'symptom_ac_water_sound'),
      ('not_cool', 'symptom_ac_not_cool'),
      ('other', 'symptom_other'),
    ],
    'fridge': [
      ('no_cool', 'symptom_fridge_no_cool'),
      ('noise', 'symptom_fridge_noise'),
      ('door', 'symptom_fridge_door'),
      ('ice', 'symptom_fridge_ice'),
      ('other', 'symptom_other'),
    ],
    'washer': [
      ('no_spin', 'symptom_washer_no_spin'),
      ('water_leak', 'symptom_washer_water_leak'),
      ('noise', 'symptom_washer_noise'),
      ('no_power', 'symptom_washer_no_power'),
      ('other', 'symptom_other'),
    ],
    'tv': [
      ('no_display', 'symptom_tv_no_display'),
      ('no_sound', 'symptom_tv_no_sound'),
      ('no_power', 'symptom_tv_no_power'),
      ('remote', 'symptom_tv_remote'),
      ('other', 'symptom_other'),
    ],
    'water_purifier': [
      ('water_leak', 'symptom_wp_water_leak'),
      ('no_cold', 'symptom_wp_no_cold'),
      ('no_hot', 'symptom_wp_no_hot'),
      ('filter', 'symptom_wp_filter'),
      ('other', 'symptom_other'),
    ],
    'fan': [
      ('no_spin', 'symptom_fan_no_spin'),
      ('noise', 'symptom_fan_noise'),
      ('no_power', 'symptom_fan_no_power'),
      ('other', 'symptom_other'),
    ],
    'rice_cooker': [
      ('no_cook', 'symptom_rc_no_cook'),
      ('no_heat', 'symptom_rc_no_heat'),
      ('no_power', 'symptom_rc_no_power'),
      ('other', 'symptom_other'),
    ],
    'generator': [
      ('no_start', 'symptom_gen_no_start'),
      ('no_power', 'symptom_gen_no_power'),
      ('noise', 'symptom_gen_noise'),
      ('fuel_leak', 'symptom_gen_fuel_leak'),
      ('other', 'symptom_other'),
    ],
    'other': [
      ('broken', 'symptom_other_broken'),
      ('noise', 'symptom_other_noise'),
      ('no_power', 'symptom_other_no_power'),
      ('other', 'symptom_other'),
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
                  ],
                ),
        ),
      ],
    );
  }
}
