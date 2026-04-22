// =============================================================================
// wizard_step2_moving.dart
// Step2: 이사 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Moving extends StatelessWidget {
  final String subTypeId;
  final String movingVehicleType;
  final String movingFloorFrom;
  final String movingFloorTo;
  final String movingElevator;
  final String movingHouseType;
  final String movingDistance;
  final Set<String> movingCargoTypes;
  final TextEditingController roomCountController;
  final TextEditingController weightKgController;
  final TextEditingController otherController;
  final String currentLangCode;
  final void Function(String) onVehicleTypeChanged;
  final void Function(String) onFloorFromChanged;
  final void Function(String) onFloorToChanged;
  final void Function(String) onElevatorChanged;
  final void Function(String) onHouseTypeChanged;
  final void Function(String) onDistanceChanged;
  final void Function(String, bool) onCargoTypeToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Moving({
    super.key,
    required this.subTypeId,
    required this.movingVehicleType,
    required this.movingFloorFrom,
    required this.movingFloorTo,
    required this.movingElevator,
    required this.movingHouseType,
    required this.movingDistance,
    required this.movingCargoTypes,
    required this.roomCountController,
    required this.weightKgController,
    required this.otherController,
    required this.currentLangCode,
    required this.onVehicleTypeChanged,
    required this.onFloorFromChanged,
    required this.onFloorToChanged,
    required this.onElevatorChanged,
    required this.onHouseTypeChanged,
    required this.onDistanceChanged,
    required this.onCargoTypeToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _floorRow(
      String labelKey, String current, void Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t(labelKey),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
        const SizedBox(height: 8),
        Row(children: [
          for (final f in [
            ('1', _t('moving_floor_1')),
            ('2', _t('moving_floor_2')),
            ('3', _t('moving_floor_3')),
            ('4+', _t('moving_floor_4plus')),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: wizardOutlineToggleTile(
                  label: f.$2,
                  selected: current == f.$1,
                  onTap: () => onSelect(current == f.$1 ? '' : f.$1),
                ),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _elevatorRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('moving_elevator'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: wizardOutlineToggleTile(
                label: _t('moving_elevator_yes'),
                selected: movingElevator == 'yes',
                onTap: () => onElevatorChanged(
                    movingElevator == 'yes' ? '' : 'yes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: wizardOutlineToggleTile(
                label: _t('moving_elevator_no'),
                selected: movingElevator == 'no',
                onTap: () => onElevatorChanged(
                    movingElevator == 'no' ? '' : 'no'),
              ),
            ),
          ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    switch (subTypeId) {
      case 'small':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('moving_vehicle_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('damas', _t('moving_vehicle_damas')),
                ('labo', _t('moving_vehicle_labo')),
                ('truck_1t', _t('moving_vehicle_truck_1t')),
                ('truck_2t', _t('moving_vehicle_truck_2t')),
              ].map((e) {
                final selected = movingVehicleType == e.$1;
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () =>
                      onVehicleTypeChanged(selected ? '' : e.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _floorRow('moving_floor_from', movingFloorFrom,
                onFloorFromChanged),
            const SizedBox(height: 12),
            _floorRow('moving_floor_to', movingFloorTo, onFloorToChanged),
            const SizedBox(height: 12),
            _elevatorRow(),
          ],
        );

      case 'home':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('moving_house_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('apartment', _t('cleaning_house_apartment')),
                ('villa', _t('cleaning_house_villa')),
                ('detached', _t('cleaning_house_detached')),
                ('officetel', _t('cleaning_house_officetel')),
              ].map((e) {
                final selected = movingHouseType == e.$1;
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () =>
                      onHouseTypeChanged(selected ? '' : e.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_t('moving_room_count'),
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
                      selected: roomCountController.text == n,
                      onTap: () {
                        roomCountController.text =
                            roomCountController.text == n ? '' : n;
                        onStateChanged();
                      },
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            _floorRow('moving_floor_from', movingFloorFrom,
                onFloorFromChanged),
            const SizedBox(height: 12),
            _floorRow('moving_floor_to', movingFloorTo, onFloorToChanged),
            const SizedBox(height: 12),
            _elevatorRow(),
          ],
        );

      case 'cargo':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('moving_cargo_type'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('furniture', _t('moving_cargo_furniture')),
                ('appliance', _t('moving_cargo_appliance')),
                ('box', _t('moving_cargo_box')),
                ('etc', _t('moving_cargo_etc')),
              ].map((e) {
                final selected = movingCargoTypes.contains(e.$1);
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () => onCargoTypeToggled(e.$1, selected),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightKgController,
              keyboardType: TextInputType.number,
              decoration: wizardOutlineFieldDecoration(
                _t('moving_weight'),
                hint: _t('moving_weight_hint'),
              ),
            ),
            const SizedBox(height: 12),
            Text(_t('moving_distance'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('local', _t('moving_distance_local')),
                ('city', _t('moving_distance_city')),
                ('intercity', _t('moving_distance_intercity')),
              ].map((e) {
                final selected = movingDistance == e.$1;
                return wizardOutlineToggleTile(
                  label: e.$2,
                  selected: selected,
                  onTap: () =>
                      onDistanceChanged(selected ? '' : e.$1),
                );
              }).toList(),
            ),
          ],
        );

      default:
        return TextField(
          controller: otherController,
          decoration: wizardOutlineFieldDecoration(
            _t('wizard_other_service_label'),
            hint: _t('wizard_other_service_hint'),
          ),
        );
    }
  }
}
