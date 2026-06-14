import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_section_header.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/logout_confirmation_dialog.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Settings tab content. Three stacked surfaces: a premium profile
/// header card, a unified card of action rows (subscription, language,
/// notifications, support, terms, delete account), and a standalone
/// logout card. Subscription details no longer render inline — the
/// `اشتراكي` row taps through to a dedicated screen.
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeaderCard(
                    user: user,
                    onEditTap: () => NavigationManager.navigateTo(
                      context,
                      RouteNames.myProfile,
                    ),
                  ),
                  QeranSpacing.vs24,
                  QeranSectionHeader(
                    title: LocaleKeys.settings_account_management.t(context),
                  ),
                  QeranSpacing.vs12,
                  _SettingsCard(onComingSoon: () => _showComingSoon(context)),
                  QeranSpacing.vs24,
                  _LogoutCard(onTap: () => _handleLogout(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    AppSnackBar.show(
      context,
      message: LocaleKeys.settings_coming_soon.t(context),
      type: SnackBarType.info,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await LogoutConfirmationDialog.show(context);
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

/// Premium header card at the top of the Settings tab. Replaces the
/// previous thin avatar+email row AND the redundant `بروفايلي` tile —
/// the user lands here daily, so the surface earns the warmth of a hero
/// strip: gold-ringed avatar, name in wine headline, completion subtitle
/// in wine-tinted body, edit-link to `MyProfile`, and a gold-tinted
/// verified chip. Layout mirrors the official identity's settings
/// mockup (avatar on the leading side in RTL, verified pill on the
/// trailing corner).
class _ProfileHeaderCard extends StatelessWidget {
  final UserEntity? user;
  final VoidCallback onEditTap;
  const _ProfileHeaderCard({required this.user, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final name = (user?.name ?? '').trim();
    final photoUrl = user?.photoUrl;
    return QeranCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(photoUrl: photoUrl),
          QeranSpacing.hs16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isNotEmpty
                      ? name
                      : LocaleKeys.home_nav_profile.t(context),
                  style: QeranTypography.headline.copyWith(
                    color: QeranColors.wine,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs4,
                // Completion subtitle. Hardcoded for now — locale keys
                // for the new settings strings are deferred per the
                // implementation roadmap.
                Text(
                  LocaleKeys.settings_profile_complete.t(context),
                  style: QeranTypography.bodySm.copyWith(
                    color: QeranColors.inkBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs8,
                _EditProfileLink(onTap: onEditTap),
              ],
            ),
          ),
          QeranSpacing.hs8,
          // Verified chip — hardcoded visible for now. Backend wiring
          // (e.g. `user?.isPhoneVerified` and any future identity-
          // verification flag) is out of scope for this milestone.
          // TODO(verification): drive visibility from a real backend flag.
          QeranChip(
            label: LocaleKeys.settings_verified.t(context),
            variant: QeranChipVariant.interest,
            icon: Icons.verified_rounded,
            compact: true,
          ),
        ],
      ),
    );
  }
}

/// 64dp circular avatar with a 1.5dp gold ring per the official
/// identity. Falls back to a wine person glyph on a gold-tinted disc
/// when no photo is available — same fallback used elsewhere in the app.
class _Avatar extends StatelessWidget {
  final String? photoUrl;
  const _Avatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: QeranColors.gold20,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (_, _, _) => const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.person_rounded,
      color: QeranColors.wine,
      size: 28,
    );
  }
}

/// Caption-sized inline link to the owner-facing profile screen.
/// Renders as `[edit icon] عرض/تعديل الملف` — gold pencil + wine label
/// — and routes to the same handler as the old quiet tile so navigation
/// behaviour is preserved exactly.
class _EditProfileLink extends StatelessWidget {
  final VoidCallback onTap;
  const _EditProfileLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 14,
                color: QeranColors.gold,
              ),
              QeranSpacing.hs4,
              Text(
                LocaleKeys.settings_view_edit_profile.t(context),
                style: QeranTypography.caption.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
  final VoidCallback onComingSoon;
  const _SettingsCard({required this.onComingSoon});

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _SubscriptionRow(),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.language_rounded,
            title: LocaleKeys.settings_language_row.t(context),
            subtitle: context.locale.languageCode == 'ar'
                ? LocaleKeys.settings_lang_arabic.t(context)
                : LocaleKeys.settings_lang_english.t(context),
            onTap: () => NavigationManager.navigateTo(
              context,
              RouteNames.settingsLanguage,
            ),
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            title: LocaleKeys.settings_notifications_row.t(context),
            subtitle: LocaleKeys.settings_notifications_sub.t(context),
            onTap: onComingSoon,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: LocaleKeys.settings_support_row.t(context),
            subtitle: LocaleKeys.settings_support_sub.t(context),
            onTap: () => NavigationManager.navigateTo(
              context,
              RouteNames.settingsSupport,
            ),
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.description_outlined,
            title: LocaleKeys.settings_terms_row.t(context),
            subtitle: LocaleKeys.settings_terms_sub.t(context),
            onTap: () => NavigationManager.navigateTo(
              context,
              RouteNames.settingsTerms,
            ),
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.delete_outline_rounded,
            title: LocaleKeys.settings_delete_account.t(context),
            subtitle: null,
            onTap: onComingSoon,
            destructive: true,
          ),
        ],
      ),
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
        return _SettingsRow(
          icon: Icons.workspace_premium_rounded,
          iconAccent: _IconAccent.gold,
          title: LocaleKeys.subscriptions_status_my_subscription.t(context),
          subtitle: subtitle,
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

enum _IconAccent { wine, gold, danger }

/// One tappable row inside the unified settings card. Owns its own
/// `InkWell` so the cream-surface highlight is scoped to the row, not
/// the whole card.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final _IconAccent iconAccent;
  final bool destructive;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconAccent = _IconAccent.wine,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = destructive
        ? QeranColors.danger
        : switch (iconAccent) {
            _IconAccent.wine => QeranColors.wine,
            _IconAccent.gold => QeranColors.gold,
            _IconAccent.danger => QeranColors.danger,
          };
    final titleColor = destructive ? QeranColors.danger : QeranColors.wine;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: QeranColors.creamSurface,
        highlightColor: QeranColors.creamSurface.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QeranColors.creamSurface,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: accentColor),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: QeranTypography.body.copyWith(color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      QeranSpacing.vs4,
                      Text(
                        subtitle!,
                        style: QeranTypography.caption.copyWith(
                          color: QeranColors.inkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                QeranSpacing.hs8,
                trailing!,
              ],
              QeranSpacing.hs8,
              const _DirectionalChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline divider drawn between settings rows. Indented past the
/// 40dp leading circle + 12dp gap + 8dp icon-to-text padding so the
/// line aligns with the row title rather than slicing under the icon.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 60, end: 16),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: QeranColors.divider),
      ),
    );
  }
}

// ── Logout card ─────────────────────────────────────────────────────

/// Standalone destructive card below the settings list. Same paper
/// treatment as the settings card but sits in its own surface so the
/// terminal action is visually segregated from the preference rows
/// above it. Behaviour preserved exactly (confirm dialog → cubit
/// signOut → clear subscription → push login).
class _LogoutCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.danger.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.logout_rounded,
              color: QeranColors.danger,
              size: 20,
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              LocaleKeys.common_logout.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.danger),
            ),
          ),
          const _DirectionalChevron(),
        ],
      ),
    );
  }
}

/// Trailing disclosure chevron. `chevron_right_rounded` auto-mirrors
/// under the ambient Directionality (matchTextDirection): points left
/// (inward) in Arabic/RTL, right in English/LTR — no manual flip.
class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right_rounded,
      color: QeranColors.wine,
      size: 22,
    );
  }
}
