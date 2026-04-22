// =============================================================================
// wizard_step2_generic.dart
// Step2: 기타 카테고리 공통 멀티셀렉트 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import 'wizard_common.dart';

class WizardStep2Generic extends StatelessWidget {
  final Set<String> step2Selections;
  final bool step2OtherSelected;
  final TextEditingController otherController;
  final String Function(String key) l10n;
  final void Function(String, bool) onSelectionToggled;
  final void Function(bool) onOtherToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Generic({
    super.key,
    required this.step2Selections,
    required this.step2OtherSelected,
    required this.otherController,
    required this.l10n,
    required this.onSelectionToggled,
    required this.onOtherToggled,
    required this.onStateChanged,
  });

  static const _options = [
    'wizard_generic_option_1',
    'wizard_generic_option_2',
    'wizard_generic_option_3',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: wizardOutlineToggleTile(
              label: l10n(o),
              selected: step2Selections.contains(o),
              onTap: () =>
                  onSelectionToggled(o, step2Selections.contains(o)),
            ),
          ),
        wizardOutlineToggleTile(
          label: context.l10n('symptom_other'),
          selected: step2OtherSelected,
          onTap: () => onOtherToggled(!step2OtherSelected),
        ),
        if (step2OtherSelected) ...[
          const SizedBox(height: 10),
          TextField(
            controller: otherController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              l10n('wizard_other_direct_input_label'),
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}
