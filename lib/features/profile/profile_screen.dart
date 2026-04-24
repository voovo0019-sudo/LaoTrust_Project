// =============================================================================
// LT-09 Feature: profile 화면 - 전화번호 로그인, 인증 배지, 프로필 메뉴
// Trust-first: Verified 배지 시스템. 화이트리스트 완전 제거 - Firebase Phone Auth 단일화
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/verified_badge_service.dart';
import '../../core/firebase_service.dart';
import '../../services/auth_service.dart';
import 'bcel_onepay_screen.dart';
import 'expert_dashboard_screen.dart';
import 'partner_support_center_screen.dart';

const String profileRouteName = '/profile';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.openPhoneAuthOnStart = false,
    this.popToHomeOnAuthSuccess = false,
    this.discardPendingPostLoginRedirect = false,
  });

  final bool openPhoneAuthOnStart;
  final bool popToHomeOnAuthSuccess;
  final bool discardPendingPostLoginRedirect;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _verified = false;

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void initState() {
    super.initState();
    if (widget.discardPendingPostLoginRedirect) {
      clearPostLoginRedirect();
    }
    _loadVerified();
    if (widget.openPhoneAuthOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _openPhoneAuthSheet(context);
      });
    }
  }

  Future<void> _loadVerified() async {
    final v = await isVerifiedBadgeActive();
    if (mounted) setState(() => _verified = v);
  }

  void _openBcelOnepay(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BcelOnepayScreen())).then((_) => _loadVerified());
  }

  void _showInfoDialog(BuildContext context, {required String messageKey}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(context.l10n(messageKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(context.l10n('profile')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n('profile_header'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileHeader(theme, colorScheme),
          const SizedBox(height: 20),
          _buildMenuTile(
            context,
            icon: Icons.account_balance_wallet,
            title: context.l10n('profile_menu_payment'),
            subtitle: context.l10n('profile_menu_payment_sub'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BcelOnepayScreen())).then((_) => _loadVerified()),
          ),
          _buildMenuTile(
            context,
            icon: Icons.assignment,
            title: context.l10n('profile_menu_my_requests'),
            subtitle: context.l10n('profile_menu_my_requests_sub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _MyRequestsScreen()),
              );
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.support_agent,
            title: context.l10n('profile_menu_customer_service'),
            subtitle: context.l10n('profile_menu_customer_service_sub'),
            onTap: () => _showInfoDialog(context, messageKey: 'profile_customer_service_ready'),
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            context,
            icon: Icons.verified,
            title: context.l10n('verified_badge_apply'),
            subtitle: _verified
                ? context.l10n('profile_verified_done')
                : context.l10n('profile_verified_todo'),
            onTap: () => _openBcelOnepay(context),
          ),
          _buildMenuTile(
            context,
            icon: Icons.dashboard,
            title: context.l10n('expert_dashboard'),
            subtitle: context.l10n('profile_expert_dashboard_sub'),
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isFirebaseEnabled && !hasRecognizedUserSession) {
                setPostLoginRedirect(expertDashboardRouteName);
                _openPhoneAuthSheet(context);
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertDashboardScreen()));
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.shield,
            title: context.t('partner_support_center_title'),
            subtitle: context.t('partner_support_center_info'),
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isFirebaseEnabled && !hasRecognizedUserSession) {
                setPostLoginRedirect(partnerSupportCenterRouteName);
                _openPhoneAuthSheet(context);
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerSupportCenterScreen()));
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.phone_iphone,
            title: context.l10n('phone_auth_title'),
            subtitle: context.l10n('phone_auth_phone_label'),
            onTap: () => _openPhoneAuthSheet(context),
          ),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: context.l10n('logout'),
            subtitle: context.l10n('logout_sub'),
            onTap: () async {
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final phone = user?.phoneNumber ?? '';
        final digits = _digitsOnly(phone);
        final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
        final displayName = last4.isNotEmpty
            ? context.l10n('home_logged_in_greeting').replaceAll('{last4}', last4)
            : context.l10n('profile_user_name');

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.person, size: 36, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_verified) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified, size: 22, color: colorScheme.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _verified
                            ? context.l10n('profile_status_verified')
                            : context.l10n('profile_status_unverified'),
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPhoneAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PhoneAuthSheet(
        onClose: () => Navigator.of(ctx).pop(),
        popToHomeOnAuthSuccess: widget.popToHomeOnAuthSuccess,
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final tile = ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: onTap == null
          ? tile
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                child: tile,
              ),
            ),
    );
  }
}

class _PhoneAuthSheet extends StatefulWidget {
  const _PhoneAuthSheet({
    required this.onClose,
    this.popToHomeOnAuthSuccess = false,
  });
  final VoidCallback onClose;
  final bool popToHomeOnAuthSuccess;

  @override
  State<_PhoneAuthSheet> createState() => _PhoneAuthSheetState();
}

class _MyRequestsScreen extends StatelessWidget {
  const _MyRequestsScreen();

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadMyRequests() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return const [];
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('requests')
        .where('uid', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(context.l10n('profile_menu_my_requests')),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _loadMyRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                context.l10n('quick_job_save_failed'),
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Text(context.l10n('profile_my_requests_empty')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final category = (data['category'] ?? '').toString();
              final status = (data['status'] ?? context.l10n('status')).toString();
              final location = (data['locationText'] ?? data['location'] ?? '-').toString();
              final createdAt = _formatDate(data['createdAt']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(category.isEmpty ? context.l10n('request_complete_title') : category),
                  subtitle: Text('$location\n$createdAt'),
                  trailing: Text(
                    status,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PhoneAuthSheetState extends State<_PhoneAuthSheet> {
  String selectedCountryCode = '+856';
  String phone = '';
  String code = '';
  bool isSending = false;
  bool isLoggingIn = false;

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _sendCode() async {
    final digits = _normalizeDigits(phone);
    if (digits.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n('phone_auth_error_invalid'))),
      );
      return;
    }

    setState(() => isSending = true);
    final currentContext = context;
    try {
      final fullNumber = '$selectedCountryCode$digits';
      await sendPhoneCode(fullNumber);
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text(currentContext.l10n('phone_auth_code_label'))),
      );
    } catch (_) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text(currentContext.l10n('phone_auth_error_invalid'))),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _finishAuthSuccessNavigate() {
    schedulePostLoginNavigationAfterAuth(
      sheetContext: context,
      closeSheet: widget.onClose,
      popToAppRoot: widget.popToHomeOnAuthSuccess,
    );
  }

  Future<void> _login() async {
    final digits = _normalizeDigits(phone);
    final inputCode = code.trim();
    if (digits.isEmpty || inputCode.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n('phone_auth_error_invalid'))),
      );
      return;
    }

    setState(() => isLoggingIn = true);
    final currentContext = context;
    try {
      await signInWithPhoneCode(inputCode);
      if (!currentContext.mounted) return;
      _finishAuthSuccessNavigate();
    } catch (_) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text(currentContext.l10n('phone_auth_error_invalid'))),
      );
    } finally {
      if (mounted) setState(() => isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Text(
            context.l10n('phone_auth_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n('phone_auth_country_label'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>(selectedCountryCode),
            initialValue: selectedCountryCode,
            items: [
              DropdownMenuItem(
                value: '+856',
                child: Text(context.l10n('phone_auth_country_laos')),
              ),
              DropdownMenuItem(
                value: '+82',
                child: Text(context.l10n('phone_auth_country_korea')),
              ),
              DropdownMenuItem(
                value: '+1',
                child: Text(context.l10n('phone_auth_country_usa')),
              ),
              DropdownMenuItem(
                value: '+66',
                child: Text(context.l10n('phone_auth_country_thailand')),
              ),
              DropdownMenuItem(
                value: '+84',
                child: Text(context.l10n('phone_auth_country_vietnam')),
              ),
              DropdownMenuItem(
                value: '+86',
                child: Text(context.l10n('phone_auth_country_china')),
              ),
              DropdownMenuItem(
                value: '+81',
                child: Text(context.l10n('phone_auth_country_japan')),
              ),
              DropdownMenuItem(
                value: '+44',
                child: Text(context.l10n('phone_auth_country_uk')),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => selectedCountryCode = v);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: context.l10n('phone_auth_phone_label'),
              hintText: context.l10n('phone_auth_phone_hint'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (v) => setState(() => phone = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: context.l10n('phone_auth_code_label'),
              hintText: context.l10n('phone_auth_code_hint'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => code = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSending ? null : _sendCode,
                  child: isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n('phone_auth_send_code')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isLoggingIn ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: isLoggingIn
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n('phone_auth_login')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
