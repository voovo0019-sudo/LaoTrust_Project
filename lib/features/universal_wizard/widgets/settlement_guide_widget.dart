// =============================================================================
// v1.3: 4단계 확정 UI 하단 — BCEL One QR 연동 안내 + 전문가 직접 지불 가이드
// 디자인: 곡률 28.0px, 로얄 네이비 #1E293B
// =============================================================================

import 'package:flutter/material.dart';
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
          const Row(
            children: [
              Icon(Icons.qr_code_2, color: UniversalWizardConfig.royalNavy, size: 24),
              SizedBox(width: 8),
              Text(
                '정산 안내',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: UniversalWizardConfig.royalNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 라오스 현지 BCEL One QR 결제 또는 현금으로 전문가에게 직접 지불할 수 있습니다.',
            style: TextStyle(
              fontSize: 13,
              color: UniversalWizardConfig.royalNavy.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• 서비스 확정 후 전문가와 만나 계약금·잔금을 정산하세요.',
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
