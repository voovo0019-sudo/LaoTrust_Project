// =============================================================================
// v1.3: 4단계 확정 UI 하단 — BCEL One QR 연동 안내 + 전문가 직접 지불 가이드
// 디자인: 곡률 28.0px, 로얄 네이비 #1E293B
// =============================================================================

import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import '../universal_wizard_config.dart';

class SettlementGuideWidget extends StatelessWidget {
  const SettlementGuideWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: UniversalWizardConfig.royalNavy, size: 24),
              const SizedBox(width: 8),
              Text(
                context.l10n('wizard_settlement_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: UniversalWizardConfig.royalNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n('wizard_settlement_line1'),
            style: TextStyle(
              fontSize: 13,
              color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n('wizard_settlement_line2'),
            style: TextStyle(
              fontSize: 13,
              color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
