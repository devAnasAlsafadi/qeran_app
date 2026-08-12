import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/design_system/widgets/qeran_section_header.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/default_name_banner_session.dart';
import 'package:qeran/features/profile/presentation/widgets/default_name_banner.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';
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

  /// Opening the name screen counts as answering the prompt, whether or not a
  /// new name is saved — so the banner is retired on the way in, not on the
  /// way back.
  Future<void> _openNameScreen() async {
    sl<DefaultNameBannerSession>().hide();
    setState(() {});
    await NavigationManager.navigateTo(context, RouteNames.settingsName);
  }

  void _dismissNameBanner() {
    sl<DefaultNameBannerSession>().hide();
    setState(() {});
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
          // Bottom-nav clearance so the last row (logout) sits fully above the
          // floating nav island + gesture inset, not behind it.
          padding: EdgeInsets.fromLTRB(
            QeranSpacing.s16,
            QeranSpacing.s16,
            QeranSpacing.s16,
            QeranBottomNav.contentClearance(context),
          ),
          child: BlocBuilder<UserSessionCubit, UserSessionState>(
            builder: (context, state) {
              final user = state is UserSessionAuthenticated ? state.user : null;
              // Prefer the authoritative profile identity from GET /api/profile
              // (reused from the already-fetched ProfileGateCubit — no second
              // fetch); fall back to the session name, then the generic label.
              // The photo is the user's own profile photo (Bearer-gated); no
              // photo → the monogram, never a generic person icon.
              final gate = context.watch<ProfileGateCubit>().state;
              final resolved = gate is ProfileGateResolved ? gate : null;
              final profileName = (resolved?.name ?? '').trim();
              final sessionName = (user?.name ?? '').trim();
              final name = profileName.isNotEmpty ? profileName : sessionName;
              // Prompt for a real name while the server-assigned placeholder
              // is still in place — unless it has already been answered this
              // run (dismissed, or the name screen was opened).
              final showNameBanner =
                  (resolved?.isDefaultName ?? false) &&
                  !sl<DefaultNameBannerSession>().isHidden;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showNameBanner)
                    DefaultNameBanner(
                      currentName: name,
                      onEdit: _openNameScreen,
                      onDismiss: _dismissNameBanner,
                    ),
                  SettingsProfileHero(
                    avatar: _HeroAvatar(photoUrl: resolved?.photoUrl, name: name),
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
                  const _UpgradeTeaserCard(),
                  QeranSpacing.vs24,
                  QeranSectionHeader(
                    title: LocaleKeys.settings_account_management.t(context),
                  ),
                  QeranSpacing.vs12,
                  _SettingsCard(
                    displayName: name,
                    onNameTap: _openNameScreen,
                  ),
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
    // Resolve the copy BEFORE the sign-out + route replacement — this context
    // is gone by the time the toast is shown.
    final message = LocaleKeys.common_logout_success.t(context);
    await context.read<UserSessionCubit>().signOut();
    // Drop the cached subscription so a future sign-in re-hydrates
    // cleanly. The bloc lives at the app root so the same instance
    // survives across login sessions.
    if (context.mounted) {
      context.read<CurrentSubscriptionCubit>().clear();
    }
    // The banner flag is per-run, not per-account — clear it so the next
    // sign-in is prompted on its own profile's terms.
    sl<DefaultNameBannerSession>().reset();
    if (!context.mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(
      context,
      RouteNames.loginScreen,
    );
    // showOnRoot (not show) so the confirmation survives the route removal.
    await AppSnackBar.showOnRoot(message: message, type: SnackBarType.success);
  }
}

/// Hero avatar for the user: their OWN profile photo (unblurred) in a gold
/// ring, otherwise the wine+gold [QeranMonogram] built from the name — never a
/// generic person icon. The photo lives on the API origin
/// (`/api/users/profile-images/...`) and is Bearer-gated, so the request
/// carries the session token (same requirement as `LikeBlurredImage`); the
/// monogram also covers the loading + load-error states.
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
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          httpHeaders: _authHeaders(context),
          fit: BoxFit.cover,
          width: 58,
          height: 58,
          placeholder: (_, _) => QeranMonogram(name: name, size: 58),
          errorWidget: (_, _, _) => QeranMonogram(name: name, size: 58),
        ),
      ),
    );
  }

  /// Bearer token for the profile-image request, from the in-scope session.
  Map<String, String>? _authHeaders(BuildContext context) {
    final state = context.read<UserSessionCubit>().state;
    if (state is UserSessionAuthenticated) {
      final token = state.user.token;
      if (token != null && token.isNotEmpty) {
        return {'Authorization': 'Bearer $token'};
      }
    }
    return null;
  }
}

// ── Settings card ──────────────────────────────────────────────────

/// Unified card hosting every settings row. Sequence is locked: identity
/// (name) first, then the subscription row (the warmest action), followed by
/// the preference rows, with the destructive `delete account` row last so
/// it doesn't sit next to logout in the visual scan.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.displayName, required this.onNameTap});

  /// Shown as the row's subtitle, so the card answers "what is my name" at a
  /// glance without opening the screen.
  final String displayName;
  final VoidCallback onNameTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.badge_outlined,
            title: LocaleKeys.profile_name_row_title.t(context),
            subtitle: displayName.isEmpty ? null : displayName,
            onTap: onNameTap,
          ),
          const SettingsRowDivider(),
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
            icon: Icons.block_outlined,
            title: LocaleKeys.block_settings_row.t(context),
            onTap: () => NavigationManager.navigateTo(
              context,
              RouteNames.blockedUsers,
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

class _UpgradeTeaserCard extends StatelessWidget {
  const _UpgradeTeaserCard();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<CurrentSubscriptionCubit, CurrentSubscriptionState>(
      builder: (context, state) {
        // Show the upsell for everyone who can still upgrade — no subscription,
        // Free (tier 0), or Basic (tier 1). Hide it ONLY for an active VIP
        // (tier 2), the top tier. Backend-driven: gate on tier +
        // isCurrentlyActive (never the plan name). Honours `lastKnown` too, so
        // a VIP doesn't flash the upsell during a transient /current failure.
        final isActiveVip = switch (state) {
          CurrentSubscriptionLoaded(:final subscription) =>
            subscription.isCurrentlyActive && subscription.plan.isVipTier,
          CurrentSubscriptionFailure(:final lastKnown) => lastKnown != null &&
              lastKnown.isCurrentlyActive &&
              lastKnown.plan.isVipTier,
          _ => false,
        };

        if (isActiveVip) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: QeranSpacing.s24),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.panelR,
            boxShadow: QeranShadows.eHero,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [QeranColors.wineLight, QeranColors.wine],
            ),
          ),
          child: ClipRRect(
            borderRadius: QeranRadii.panelR,
            child: Stack(
              children: [
                // Circular background overlay decoration
                Positioned(
                  top: -50,
                  right: -30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: QeranColors.gold.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: QeranColors.gold.withValues(alpha: 0.18),
                              border: Border.all(color: QeranColors.gold, width: 1.2),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: QeranColors.gold,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'ارتقِ لعضوية التميز' : 'Upgrade to Premium',
                                  style: QeranTypography.subtitle.copyWith(
                                    color: QeranColors.paper,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isArabic
                                      ? 'افتح كافة ميزات قِران الفريدة وتعرّف على شريكك اليوم'
                                      : 'Unlock premium features and find your match today',
                                  style: QeranTypography.bodySm.copyWith(
                                    color: QeranColors.gold.withValues(alpha: 0.80),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      QeranSpacing.vs16,
                      // Teasers list
                      _TeaserRow(
                        label: isArabic
                            ? 'إعجابات وتواصل بلا حدود مع الطرف الآخر'
                            : 'Unlimited likes and match connections',
                      ),
                      _TeaserRow(
                        label: isArabic
                            ? 'تبادل الصور بأمان وسرية تامة'
                            : 'Secure and private photo exchange',
                      ),
                      const SizedBox(height: 18),
                      QeranButton(
                        label: isArabic ? 'اكتشف الباقات' : 'See Plans',
                        onPressed: () => NavigationManager.navigateTo(
                          context,
                          RouteNames.packagesScreen,
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
}

class _TeaserRow extends StatelessWidget {
  final String label;
  const _TeaserRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.done_rounded,
            color: QeranColors.gold,
            size: 18,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              label,
              style: QeranTypography.bodySm.copyWith(
                color: QeranColors.paper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
