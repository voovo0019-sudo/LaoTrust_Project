// =============================================================================
// wizard_step4.dart
// Step4: 신청 내용 최종 확인 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../universal_wizard_config.dart';
import '../universal_wizard_state.dart';
import '../widgets/settlement_guide_widget.dart';
import 'wizard_common.dart';

class WizardStep4 extends StatelessWidget {
  final UniversalWizardConfig config;
  final UniversalWizardState state;
  final String depth2Display;
  final String Function(String key) l10n;
  final String Function(String key) t;
  final TextEditingController landmarkController;
  final TextEditingController movingFromController;
  final TextEditingController movingToController;
  final TextEditingController memoController;

  const WizardStep4({
    super.key,
    required this.config,
    required this.state,
    required this.depth2Display,
    required this.l10n,
    required this.t,
    required this.landmarkController,
    required this.movingFromController,
    required this.movingToController,
    required this.memoController,
  });

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: kWizardRoyalBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n('wizard_summary_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kWizardRoyalBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n('wizard_step4_desc_v5'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          _summaryRow(
            l10n('wizard_summary_category'),
            l10n(config.categoryKey),
          ),
          _summaryRow(
            l10n('wizard_summary_subtype'),
            state.step1SubTypeLabel.isEmpty
                ? ''
                : l10n(state.step1SubTypeLabel),
          ),
          _summaryRow(
            l10n('wizard_summary_depth2'),
            depth2Display,
          ),
          _summaryRow(
            l10n('wizard_summary_location'),
            state.categoryKey == 'expert_moving'
                ? '${l10n('wizard_depth3_from_label')}: '
                    '${movingFromController.text}\n'
                    '${l10n('wizard_depth3_to_label')}: '
                    '${movingToController.text}\n'
                    '${l10n('wizard_depth3_landmark_label')}: '
                    '${landmarkController.text}'
                : landmarkController.text,
          ),
          if (state.step3Lat != null)
            _summaryRow('GPS', '${state.step3Lat}, ${state.step3Lng}'),
          _summaryRow(
            l10n('wizard_summary_schedule'),
            '${state.preferredDateStr} ${state.preferredTimeStr} '
                '(${state.scheduleIsUrgent ? l10n('wizard_schedule_urgent') : l10n('wizard_schedule_normal')})',
          ),
          _summaryRow(
            l10n('wizard_summary_photos'),
            '${state.step3PhotoPaths.length}'
                '${l10n('wizard_summary_photos_unit')}',
          ),
          if (memoController.text.trim().isNotEmpty)
            _summaryRow(
              l10n('wizard_summary_note'),
              memoController.text.trim(),
            ),
          const SizedBox(height: 24),
          const SettlementGuideWidget(),
        ],
      ),
    );
  }
}
