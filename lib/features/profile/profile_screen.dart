// =============================================================================
// LT-09 Feature: profile 화면 - 전화번호 로그인, 인증 배지, 프로필 메뉴
// Trust-first: Verified 배지 시스템. 화이트리스트 완전 제거 - Firebase Phone Auth 단일화
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/providers.dart';
import '../../core/app_localizations.dart';
import '../../core/translation_mapper.dart';
import '../../core/verified_badge_service.dart';
import '../../core/firebase_service.dart';
import '../../data/firestore_schema.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../services/google_auth_service.dart';

const String profileRouteName = '/profile';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.openPhoneAuthOnStart = false,
    this.popToHomeOnAuthSuccess = false,
    this.discardPendingPostLoginRedirect = false,
    this.acceptedCount = 0,
    this.pendingApplicantCount = 0,
    this.unseenApplicationCount = 0,
  });

  final bool openPhoneAuthOnStart;
  final bool popToHomeOnAuthSuccess;
  final bool discardPendingPostLoginRedirect;
  final int acceptedCount;
  final int pendingApplicantCount;
  final int unseenApplicationCount;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _verified = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _savingProfile = false;
  bool _profileSaved = false;
  String _selectedCountryCode = '+856';

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void initState() {
    super.initState();
    if (widget.discardPendingPostLoginRedirect) {
      clearPostLoginRedirect();
    }
    _loadVerified();
    _loadUserProfile();
    if (widget.openPhoneAuthOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _openGoogleAuthFlow(context);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadVerified() async {
    final v = await isVerifiedBadgeActive();
    if (mounted) setState(() => _verified = v);
  }

  Future<void> _loadUserProfile() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(kColUsers)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data[UserFields.displayName]?.toString() ?? '';
          final savedPhone = data[UserFields.phone]?.toString() ?? '';
          // 저장된 전화번호에서 국가코드 분리
          final matchedCode = kCountryPhoneCodes
              .map((e) => e['code']!)
              .firstWhere(
                (code) => savedPhone.startsWith(code),
                orElse: () => '+856',
              );
          if (savedPhone.startsWith(matchedCode)) {
            _selectedCountryCode = matchedCode;
            _phoneController.text =
                savedPhone.substring(matchedCode.length).trim();
          } else {
            _phoneController.text = savedPhone;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _savingProfile = true);
    try {
      await FirebaseService().updateUserProfile(
        uid: uid,
        displayName: _nameController.text,
        phone: '$_selectedCountryCode ${_phoneController.text.trim()}',
      );
      if (mounted) {
        setState(() => _profileSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n('profile_save_success'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n('error_update_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(currentTabProvider.notifier).goHome(),
        ),
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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n('profile_edit_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() => _profileSaved = false),
                  decoration: InputDecoration(
                    labelText: context.l10n('profile_edit_name'),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_outline,
                        color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetCtx) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E3A8A)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.public,
                                              color: Color(0xFF1E3A8A),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          context.l10n('phone_auth_country_label'),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(sheetCtx).size.height *
                                              0.5,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: kCountryPhoneCodes.length,
                                      itemBuilder: (_, i) {
                                        final item = kCountryPhoneCodes[i];
                                        final isSelected =
                                            item['code'] == _selectedCountryCode;
                                        return ListTile(
                                          leading: Text(
                                            item['flag'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 24),
                                          ),
                                          title: Text(
                                            '${item['name']} (${item['code']})',
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? const Icon(Icons.check_circle,
                                                  color: Color(0xFF1E3A8A))
                                              : null,
                                          onTap: () => Navigator.of(sheetCtx)
                                              .pop(item['code']),
                                        );
                                      },
                                    ),
                                  ),
                                  const SafeArea(
                                    child: SizedBox(height: 8),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            _selectedCountryCode = selected;
                            _profileSaved = false;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              kCountryPhoneCodes.firstWhere(
                                (e) => e['code'] == _selectedCountryCode,
                                orElse: () => kCountryPhoneCodes[0],
                              )['flag'] ?? '',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCountryCode,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down,
                                size: 18, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        onChanged: (_) => setState(() => _profileSaved = false),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: kCountryPhoneCodes.firstWhere(
                            (e) => e['code'] == _selectedCountryCode,
                            orElse: () => kCountryPhoneCodes[0],
                          )['hint'] ?? 'Phone number',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingProfile ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _savingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _profileSaved
                                ? context.l10n('profile_save_success')
                                : context.l10n('profile_save'),
                          ),
                  ),
                ),
              ],
            ),
          ),
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
            badgeCount: widget.acceptedCount,
            onTap: () => context.push('/my_requests'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.request_quote_outlined,
            title: context.t('my_quotes_title'),
            subtitle: context.t('quote_btn_send'),
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isFirebaseEnabled && !hasRecognizedUserSession) {
                setPostLoginRedirect('/my_quotes');
                _openGoogleAuthFlow(context);
                return;
              }
              context.push('/my_quotes');
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.people_outline,
            title: context.l10n('my_job_posts'),
            subtitle: context.l10n('my_job_posts_sub'),
            badgeCount: widget.pendingApplicantCount,
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isFirebaseEnabled && !hasRecognizedUserSession) {
                setPostLoginRedirect('/my_job_applicants');
                _openGoogleAuthFlow(context);
                return;
              }
              context.push('/my_job_applicants');
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.send_outlined,
            title: context.l10n('my_applications'),
            subtitle: context.l10n('my_applications_sub'),
            badgeCount: widget.unseenApplicationCount,
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isFirebaseEnabled && !hasRecognizedUserSession) {
                setPostLoginRedirect('/my_applications');
                _openGoogleAuthFlow(context);
                return;
              }
              context.push('/my_applications');
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
            icon: Icons.workspace_premium,
            title: context.t('expert_reg_title'),
            subtitle: context.t('expert_reg_menu_sub'),
            onTap: () async {
              await finalizeAppAuthState();
              if (!context.mounted) return;
              if (isFirebaseEnabled && !hasRecognizedUserSession) {
                setPostLoginRedirect('/expert_registration');
                _openGoogleAuthFlow(context);
                return;
              }
              context.push('/expert_registration');
            },
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
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badgeCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        const Icon(Icons.chevron_right),
      ],
    );
    final tile = ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
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
