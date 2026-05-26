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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  const QeranSectionHeader(title: 'إعدادات'),
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
      message: 'قريباً',
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
                  'الملف الشخصي مكتمل',
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
          const QeranChip(
            label: 'موثق',
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
                'عرض/تعديل الملف',
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
            title: 'تغيير اللغة',
            subtitle: 'العربية',
            onTap: onComingSoon,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            subtitle: 'إعدادات التنبيهات',
            onTap: onComingSoon,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'المساعدة والدعم',
            subtitle: 'تواصل معنا',
            onTap: onComingSoon,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.description_outlined,
            title: 'الشروط والأحكام',
            subtitle: 'سياسة الاستخدام',
            onTap: onComingSoon,
          ),
          const _RowDivider(),
          _SettingsRow(
            icon: Icons.delete_outline_rounded,
            title: 'حذف أو تجميد الحساب',
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
        final (subtitle, showUpgrade) = _resolve(state);
        return _SettingsRow(
          icon: Icons.workspace_premium_rounded,
          iconAccent: _IconAccent.gold,
          title: LocaleKeys.subscriptions_status_my_subscription.t(context),
          subtitle: subtitle,
          trailing: showUpgrade
              ? const QeranChip(
                  label: 'ترقية',
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

  /// Returns `(subtitle, showUpgradePill)` per state.
  (String, bool) _resolve(CurrentSubscriptionState state) {
    return switch (state) {
      CurrentSubscriptionLoaded(:final subscription) =>
        subscription.isCurrentlyActive
            ? (
                '${subscription.plan.nameAr} - ${subscription.daysRemaining} يوم متبقي',
                false,
              )
            : ('انتهت صلاحية الاشتراك', true),
      CurrentSubscriptionFailure(:final lastKnown)
          when lastKnown != null && lastKnown.isCurrentlyActive =>
        (
          '${lastKnown.plan.nameAr} - ${lastKnown.daysRemaining} يوم متبقي',
          false,
        ),
      _ => ('لا يوجد اشتراك نشط', true),
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

/// RTL-aware trailing chevron — auto-mirrors to point inward toward the
/// content rather than off-screen in Arabic.
class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      color: QeranColors.wine,
      size: 22,
    );
  }
}
