// =============================================================================
// wizard_step1.dart
// Step1: 서비스 유형 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../universal_wizard_config.dart';
import '../universal_wizard_state.dart';
import 'wizard_common.dart';

class WizardStep1 extends StatelessWidget {
  final UniversalWizardConfig config;
  final UniversalWizardState state;
  final void Function(String id, String label) onSubTypeSelected;
  final String Function(String key) l10n;

  const WizardStep1({
    super.key,
    required this.config,
    required this.state,
    required this.onSubTypeSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n('wizard_step1_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kWizardRoyalBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n('wizard_step1_desc_v5'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          ...config.step1SubTypes.map((e) {
            final selected = state.step1SubTypeId == e.key;
            final label = l10n(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSubTypeSelected(
                    selected ? '' : e.key,
                    selected ? '' : e.value,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? kWizardRoyalBlue.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: selected
                            ? kWizardRoyalBlue
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected ? kWizardRoyalBlue : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: kWizardRoyalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
