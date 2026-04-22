// =============================================================================
// wizard_step2_vehicle.dart
// Step2: 자동차·렌트 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Vehicle extends StatelessWidget {
  final String subTypeId;
  final Set<String> vehicleSymptoms;
  final Set<String> step2Selections;
  final TextEditingController brandController;
  final TextEditingController symptomMemoController;
  final String currentLangCode;
  final void Function(String, bool) onSymptomToggled;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Vehicle({
    super.key,
    required this.subTypeId,
    required this.vehicleSymptoms,
    required this.step2Selections,
    required this.brandController,
    required this.symptomMemoController,
    required this.currentLangCode,
    required this.onSymptomToggled,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _brandField() => TextField(
        controller: brandController,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('wizard_vehicle_brand_label'),
          hint: _t('wizard_vehicle_brand_hint'),
        ),
      );

  Widget _symptomMemo() => TextField(
        controller: symptomMemoController,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('vehicle_symptom_memo_label'),
          hint: _t('vehicle_symptom_memo_hint'),
        ),
        maxLines: 3,
      );

  Widget _durationRow() {
    const durations = [
      ('half_day', 'vehicle_rental_half_day'),
      ('full_day', 'vehicle_rental_full_day'),
      ('weekly', 'vehicle_rental_weekly'),
      ('monthly', 'vehicle_rental_monthly'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('vehicle_rental_duration_title'),
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

  @override
  Widget build(BuildContext context) {
    if (subTypeId == 'car_repair') {
      const symptoms = [
        ('engine', 'wizard_vehicle_sym_engine'),
        ('tire', 'wizard_vehicle_sym_tire'),
        ('accident', 'wizard_vehicle_sym_accident'),
        ('electrical', 'wizard_vehicle_sym_electrical'),
        ('brake', 'vehicle_sym_brake'),
        ('ac', 'vehicle_sym_ac'),
        ('other', 'symptom_other'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandField(),
          const SizedBox(height: 16),
          Text(_t('wizard_vehicle_symptom_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((e) {
              final selected = vehicleSymptoms.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSymptomToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _symptomMemo(),
        ],
      );
    }

    if (subTypeId == 'moto_repair') {
      const symptoms = [
        ('engine', 'wizard_vehicle_sym_engine'),
        ('tire', 'wizard_vehicle_sym_tire'),
        ('brake', 'vehicle_sym_brake'),
        ('electrical', 'wizard_vehicle_sym_electrical'),
        ('chain', 'vehicle_sym_chain'),
        ('other', 'symptom_other'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandField(),
          const SizedBox(height: 16),
          Text(_t('wizard_vehicle_symptom_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((e) {
              final selected = vehicleSymptoms.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSymptomToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _symptomMemo(),
        ],
      );
    }

    if (subTypeId == 'car_rental') {
      const carTypes = [
        ('sedan', 'vehicle_car_sedan'),
        ('suv', 'vehicle_car_suv'),
        ('van', 'vehicle_car_van'),
        ('pickup', 'vehicle_car_pickup'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('vehicle_car_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: carTypes.map((e) {
              final selected = vehicleSymptoms.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSymptomToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _durationRow(),
          const SizedBox(height: 16),
          TextField(
            controller: brandController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('vehicle_rental_brand_label'),
              hint: _t('vehicle_rental_brand_hint'),
            ),
          ),
        ],
      );
    }

    if (subTypeId == 'moto_rental') {
      const motoTypes = [
        ('scooter', 'vehicle_moto_scooter'),
        ('semi_auto', 'vehicle_moto_semi_auto'),
        ('manual', 'vehicle_moto_manual'),
        ('big_bike', 'vehicle_moto_big_bike'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('vehicle_moto_type_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: motoTypes.map((e) {
              final selected = vehicleSymptoms.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSymptomToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _durationRow(),
          const SizedBox(height: 16),
          TextField(
            controller: brandController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('vehicle_rental_brand_label'),
              hint: _t('vehicle_moto_rental_brand_hint'),
            ),
          ),
        ],
      );
    }

    if (subTypeId == 'tire_battery') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandField(),
          const SizedBox(height: 16),
          Text(
            _t('wizard_vehicle_symptom_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('flat', 'vehicle_sym_tire'),
              ('battery', 'vehicle_sym_electrical'),
              ('other', 'symptom_other'),
            ].map((e) {
              final selected = vehicleSymptoms.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSymptomToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _symptomMemo(),
        ],
      );
    }

    if (subTypeId == 'carwash') {
      const carwashTypes = [
        ('basic', 'vehicle_carwash_basic'),
        ('interior', 'vehicle_carwash_interior'),
        ('full', 'vehicle_carwash_full'),
        ('coating', 'vehicle_carwash_coating'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('vehicle_carwash_type_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: carwashTypes.map((e) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brandField(),
        const SizedBox(height: 16),
        _symptomMemo(),
      ],
    );
  }
}
