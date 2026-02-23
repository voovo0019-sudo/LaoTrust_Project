// =============================================================================
// LT-09 Feature: profile — BCEL OnePay QR 결제 시뮬 (4.5 USD → Verified)
// Handover: 실제 PG 연동 시 이 화면만 교체. 한/영 주석.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/verified_badge_service.dart';

const String bcelOnepayRouteName = '/bcel-onepay';
const double kVerificationFeeUsd = 4.5;

class BcelOnepayScreen extends StatefulWidget {
  const BcelOnepayScreen({super.key});

  @override
  State<BcelOnepayScreen> createState() => _BcelOnepayScreenState();
}

class _BcelOnepayScreenState extends State<BcelOnepayScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;

  Future<void> _simulatePaymentComplete() async {
    if (_isProcessing || _paymentSuccess) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    await setVerifiedBadgeActive(true);
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _paymentSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BCEL OnePay'),
      ),
      body: SafeArea(
        child: _paymentSuccess ? _buildSuccessBody(context, colorScheme) : _buildPaymentBody(theme, colorScheme),
      ),
    );
  }

  Widget _buildPaymentBody(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Verified Badge 인증 결제',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '인증의 혜택: 상단 노출, 신뢰 배지 등',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  context.l10n('payment_amount'),
                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${kVerificationFeeUsd.toStringAsFixed(1)} USD',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Text(
                    'QR\n(시뮬)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BCEL OnePay 앱으로 QR 스캔 후 결제',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _simulatePaymentComplete,
            icon: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isProcessing ? '결제 처리 중...' : '결제 완료 (시뮬레이션)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBody(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            context.l10n('payment_success'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('payment_success_badge'),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(context.l10n('go_home')),
          ),
        ],
      ),
    );
  }
}
