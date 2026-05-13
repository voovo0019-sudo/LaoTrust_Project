// =============================================================================
// LT-09 Feature: profile 화면 - 전화번호 로그인, 인증 배지, 프로필 메뉴
// Trust-first: Verified 배지 시스템. 화이트리스트 완전 제거 - Firebase Phone Auth 단일화
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_localizations.dart';
import '../../core/verified_badge_service.dart';
import '../../core/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';

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
        _openGoogleAuthFlow(context);
      });
    }
  }

  Future<void> _loadVerified() async {
    final v = await isVerifiedBadgeActive();
    if (mounted) setState(() => _verified = v);
  }

  void _openBcelOnepay(BuildContext context) {
    context.push('/bcel_onepay').then((_) => _loadVerified());
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
            onTap: () => context.push('/bcel_onepay').then((_) => _loadVerified()),
          ),
          _buildMenuTile(
            context,
            icon: Icons.assignment,
            title: context.l10n('profile_menu_my_requests'),
            subtitle: context.l10n('profile_menu_my_requests_sub'),
            onTap: () => context.push('/my_requests'),
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
                setPostLoginRedirect('/expert_dashboard');
                _openGoogleAuthFlow(context);
                return;
              }
              context.push('/expert_dashboard');
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
                setPostLoginRedirect('/partner_support');
                _openGoogleAuthFlow(context);
                return;
              }
              context.push('/partner_support');
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.g_mobiledata,
            title: context.l10n('google_login_title'),
            subtitle: context.l10n('google_login_subtitle'),
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isGoogleSignedIn) {
                _showInfoDialog(context, messageKey: 'google_already_logged_in');
                return;
              }
              try {
                final result = await signInWithGoogle();
                if (result == null) return;
                if (!context.mounted) return;
                schedulePostLoginNavigationAfterAuth(
                  sheetContext: context,
                  closeSheet: () {},
                  popToAppRoot: widget.popToHomeOnAuthSuccess,
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n('google_login_error'))),
                );
              }
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: context.l10n('logout'),
            subtitle: context.l10n('logout_sub'),
            onTap: () async {
              if (isGoogleSignedIn) {
                await signOutGoogle();
              } else {
                await auth.signOut();
              }
              if (!context.mounted) return;
              context.go('/main');
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
        final isGoogle = isGoogleSignedIn;
        final displayName = isGoogle
            ? (user?.displayName ?? user?.email ?? context.l10n('profile_user_name'))
            : () {
                final phone = user?.phoneNumber ?? '';
                final digits = _digitsOnly(phone);
                final last4 = digits.length >= 4
                    ? digits.substring(digits.length - 4)
                    : '';
                return last4.isNotEmpty
                    ? context.l10n('home_logged_in_greeting').replaceAll('{last4}', last4)
                    : context.l10n('profile_user_name');
              }();
        final photoUrl = user?.photoURL;
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
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, size: 36, color: colorScheme.onPrimaryContainer)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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

  Future<void> _openGoogleAuthFlow(BuildContext context) async {
    try {
      final result = await signInWithGoogle();
      if (result == null) return;
      if (!context.mounted) return;
      schedulePostLoginNavigationAfterAuth(
        sheetContext: context,
        closeSheet: () {},
        popToAppRoot: widget.popToHomeOnAuthSuccess,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n('google_login_error'))),
      );
    }
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
