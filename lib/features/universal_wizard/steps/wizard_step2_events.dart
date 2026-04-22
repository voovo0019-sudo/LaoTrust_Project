// =============================================================================
// wizard_step2_events.dart
// Step2: 이벤트·사진 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Events extends StatelessWidget {
  final String subTypeId;
  final Set<String> step2Selections;
  final TextEditingController peopleController;
  final TextEditingController memoController;
  final String currentLangCode;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Events({
    super.key,
    required this.subTypeId,
    required this.step2Selections,
    required this.peopleController,
    required this.memoController,
    required this.currentLangCode,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  Widget _peopleField() => TextField(
        controller: peopleController,
        keyboardType: TextInputType.number,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('wizard_event_people_label'),
          hint: _t('wizard_event_people_hint'),
        ),
      );

  Widget _memoField() => TextField(
        controller: memoController,
        onChanged: (_) => onStateChanged(),
        decoration: wizardOutlineFieldDecoration(
          _t('events_detail_label'),
          hint: _t('events_detail_hint'),
        ),
        maxLines: 3,
      );

  @override
  Widget build(BuildContext context) {
    if (subTypeId == 'wedding_photo' || subTypeId == 'portrait' ||
        subTypeId == 'commercial' || subTypeId == 'drone') {
      const photoStyles = [
        ('natural', 'events_photo_natural'),
        ('studio', 'events_photo_studio'),
        ('outdoor', 'events_photo_outdoor'),
        ('indoor', 'events_photo_indoor'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('events_photo_style_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photoStyles.map((e) {
              final selected = step2Selections.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSelectionToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(_t('events_deliverable_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('photo_only', 'events_deliverable_photo'),
              ('video_only', 'events_deliverable_video'),
              ('both', 'events_deliverable_both'),
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
          _peopleField(),
          const SizedBox(height: 16),
          _memoField(),
        ],
      );
    }

    if (subTypeId == 'party' || subTypeId == 'catering' ||
        subTypeId == 'mc_dj') {
      const scales = [
        ('scale_s', 'events_scale_s'),
        ('scale_m', 'events_scale_m'),
        ('scale_l', 'events_scale_l'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('events_scale_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kWizardRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scales.map((e) {
              final selected = step2Selections.contains(e.$1);
              return wizardOutlineToggleTile(
                label: _t(e.$2),
                selected: selected,
                onTap: () => onSelectionToggled(e.$1, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _peopleField(),
          const SizedBox(height: 16),
          _memoField(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _peopleField(),
        const SizedBox(height: 16),
        _memoField(),
      ],
    );
  }
}
