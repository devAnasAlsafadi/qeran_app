import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/design_system/widgets/qeran_section_header.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/notifications/presentation/routing/open_notifications.dart';
import 'package:qeran/features/auth/presentation/widgets/change_password_sheet.dart';
import 'package:qeran/features/profile/presentation/widgets/delete_account_sheet.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_language_sheet.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_logout_card.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_profile_hero.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_row.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Settings tab content. A wine hero (avatar + name + edit link), a unified
/// card of action rows (subscription, language, notifications, support, terms,
/// change password, delete account), and a standalone logout card. Composes
/// the shared settings kit (`SettingsProfileHero` / `SettingsRow` /
/// `SettingsLogoutCard`) — the matchmaker account screen uses the same atoms.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Soft refresh — the cubit short-circuits inside its 60 s TTL so
    // tab navigation doesn't spam /current. The subscription details
    // screen still consumes the same cubit, so a warm cache here is
    // a hit there too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CurrentSubscriptionCubit>().refresh();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<CurrentSubscriptionCubit>().refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: QeranColors.wine,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s16,
            QeranSpacing.s16,
            QeranSpacing.s16,
            QeranSpacing.s24,
          ),
          child: BlocBuilder<UserSessionCubit, UserSessionState>(
            builder: (context, state) {
              final user = state is UserSessionAuthenticated ? state.user : null;
              final name = (user?.name ?? '').trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsProfileHero(
                    avatar: _HeroAvatar(photoUrl: user?.photoUrl, name: name),
                    name: name.isNotEmpty
                        ? name
                        : LocaleKeys.home_nav_profile.t(context),
                    editLabel:
                        LocaleKeys.settings_view_edit_profile.t(context),
                    onEdit: () => NavigationManager.navigateTo(
                      context,
                      RouteNames.myProfile,
                    ),
                    // موثّق badge + "الملف الشخصي مكتمل" are gated on a real
                    // backend flag that isn't wired yet — hidden until then so
                    // we never fabricate a verified/complete state. When the
                    // field lands, pass `verified: user.isVerified` /
                    // `completionLabel: … if user.profileComplete`. (See HANDOFF.)
                    verified: false,
                    completionLabel: null,
                  ),
                  QeranSpacing.vs24,
                  QeranSectionHeader(
                    title: LocaleKeys.settings_account_management.t(context),
                  ),
                  QeranSpacing.vs12,
                  const _SettingsCard(),
                  QeranSpacing.vs24,
                  SettingsLogoutCard(onTap: () => _handleLogout(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.dialogs_logout_title.t(context),
      message: LocaleKeys.dialogs_logout_message.t(context),
      confirmLabel: LocaleKeys.common_logout.t(context),
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<UserSessionCubit>().signOut();
    // Drop the cached subscription so a future sign-in re-hydrates
    // cleanly. The bloc lives at the app root so the same instance
    // survives across login sessions.
    if (context.mounted) {
      context.read<CurrentSubscriptionCubit>().clear();
    }
    if (!context.mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(
      context,
      RouteNames.loginScreen,
    );
  }
}

/// Hero avatar for the user: the session photo when present (with a
/// monogram fallback if it fails to load), otherwise the wine+gold
/// [QeranMonogram] built from the name.
class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    if (!hasPhoto) return QeranMonogram(name: name, size: 64);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          width: 58,
          height: 58,
          errorBuilder: (_, _, _) => QeranMonogram(name: name, size: 58),
        ),
      ),
    );
  }
}

// ── Settings card ──────────────────────────────────────────────────

/// Unified card hosting every settings row. Sequence is locked: the
/// subscription row is first (the warmest action), followed by the
/// preference rows, with the destructive `delete account` row last so
/// it doesn't sit next to logout in the visual scan.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _SubscriptionRow(),
          const SettingsRowDivider(),
          SettingsRow(
            icon: Icons.language_rounded,
            title: LocaleKeys.settings_language_row.t(context),
            subtitle: context.locale.languageCode == 'ar'
                ? LocaleKeys.settings_lang_arabic.t(context)
                : LocaleKeys.settings_lang_english.t(context),
            onTap: () => showSettingsLanguageSheet(context),
          ),
          const SettingsRowDivider(),
          SettingsRow(
            icon: Icons.notifications_outlined,
            title: LocaleKeys.settings_notifications_row.t(context),
            subtitle: LocaleKeys.settings_notifications_sub.t(context),
            onTap: () => openNotifications(context),
          ),
          const SettingsRowDivider(),
          SettingsRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: LocaleKeys.settings_support_row.t(context),
            subtitle: LocaleKeys.settings_support_sub.t(context),
            onTap: () => NavigationManager.navigateTo(
              context,
              RouteNames.settingsSupport,
            ),
          ),
          const SettingsRowDivider(),
          SettingsRow(
            icon: Icons.description_outlined,
            title: LocaleKeys.settings_terms_row.t(context),
            subtitle: LocaleKeys.settings_terms_sub.t(context),
            onTap: () => NavigationManager.navigateTo(
              context,
              RouteNames.settingsTerms,
            ),
          ),
          const SettingsRowDivider(),
          SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: LocaleKeys.settings_change_password_title.t(context),
            onTap: () => showChangePasswordSheet(context),
          ),
          const SettingsRowDivider(),
          SettingsRow(
            icon: Icons.delete_outline_rounded,
            title: LocaleKeys.settings_delete_account.t(context),
            onTap: () => _openDeleteAccount(context),
            accent: SettingsRowAccent.danger,
          ),
        ],
      ),
    );
  }

  /// Opens the permanent-delete confirmation sheet, passing the current
  /// subscription's active state + expiry (read from the already-hydrated
  /// cubit) so the sheet can warn about forfeiting the remaining time.
  void _openDeleteAccount(BuildContext context) {
    final state = context.read<CurrentSubscriptionCubit>().state;
    final sub = state is CurrentSubscriptionLoaded ? state.subscription : null;
    final active = sub?.isCurrentlyActive ?? false;
    showDeleteAccountSheet(
      context,
      subscriptionActive: active,
      expiresAt: active ? sub!.expiresAt : null,
    );
  }
}

/// First row in the settings card. Reads `CurrentSubscriptionCubit` to
/// drive the subtitle (active plan + days remaining / "no active sub"
/// / "expired") and to decide whether to render the trailing `ترقية`
/// gold pill. Taps through to `subscriptionDetails`.
class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentSubscriptionCubit, CurrentSubscriptionState>(
      builder: (context, state) {
        final (subtitle, showUpgrade) = _resolve(context, state);
        return SettingsRow(
          icon: Icons.workspace_premium_rounded,
          accent: SettingsRowAccent.gold,
          title: LocaleKeys.subscriptions_status_my_subscription.t(context),
          // `showUpgrade` is true exactly when there's no active subscription
          // (expired / none / loading) — nudge toward اشتراكي for restore;
          // an active sub keeps its dynamic "plan · days" subtitle.
          subtitle: showUpgrade
              ? LocaleKeys
                  .subscriptions_subscription_row_subtitle_with_restore
                  .t(context)
              : subtitle,
          trailing: showUpgrade
              ? QeranChip(
                  label: LocaleKeys.settings_upgrade.t(context),
                  variant: QeranChipVariant.interest,
                  compact: true,
                )
              : null,
          onTap: () => NavigationManager.navigateTo(
            context,
            RouteNames.subscriptionDetails,
          ),
        );
      },
    );
  }

  /// Returns `(subtitle, showUpgradePill)` per state. Locale-aware: plan name
  /// + "days remaining" follow `context.locale` (the backend ships bilingual
  /// fields; never hardcode one).
  (String, bool) _resolve(BuildContext context, CurrentSubscriptionState state) {
    final isArabic = context.locale.languageCode == 'ar';
    String activeSubtitle(String name, int daysRemaining) {
      final days = LocaleKeys.subscriptions_status_days_remaining
          .t(context)
          .replaceFirst('{days}', '$daysRemaining');
      return '$name · $days';
    }

    return switch (state) {
      CurrentSubscriptionLoaded(:final subscription) =>
        subscription.isCurrentlyActive
            ? (
                activeSubtitle(
                  subscription.plan.name(isArabic: isArabic),
                  subscription.daysRemaining,
                ),
                false,
              )
            : (
                LocaleKeys.subscriptions_status_expired_subtitle.t(context),
                true,
              ),
      CurrentSubscriptionFailure(:final lastKnown)
          when lastKnown != null && lastKnown.isCurrentlyActive =>
        (
          activeSubtitle(
            lastKnown.plan.name(isArabic: isArabic),
            lastKnown.daysRemaining,
          ),
          false,
        ),
      _ => (LocaleKeys.subscriptions_status_none_subtitle.t(context), true),
    };
  }
}
