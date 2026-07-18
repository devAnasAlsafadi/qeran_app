import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_sheet.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_hero_badge.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/generated/locale_keys.g.dart';

part 'photo_exchange_limit_sheet_parts.dart';

/// Bottom sheet shown when a SUBSCRIBED user requests one more photo exchange
/// after exhausting their plan's per-period quota (`PHOTO_EXCHANGE_LIMIT_REACHED`).
///
/// This is an UPGRADE prompt, never a "subscribe" gate — the copy never says
/// "subscribe". The plan badge and renewal pill are backend-driven: each shows
/// only when [subscription] backs it (plan name present / reliable `expiresAt`).
Future<void> showPhotoExchangeLimitSheet(
  BuildContext context, {
  CurrentSubscription? subscription,
}) {
  return showQeranBottomSheet<void>(
    context: context,
    builder: (sheetContext) => PhotoExchangeLimitSheet(
      subscription: subscription,
      // Pop the sheet, then navigate on the OUTER (screen) context so Back
      // from Plans returns to Likes, not the dismissed sheet.
      onUpgrade: () {
        Navigator.of(sheetContext).pop();
        NavigationManager.navigateTo(context, RouteNames.packagesScreen);
      },
    ),
  );
}

class PhotoExchangeLimitSheet extends StatelessWidget {
  const PhotoExchangeLimitSheet({
    super.key,
    required this.subscription,
    required this.onUpgrade,
  });

  final CurrentSubscription? subscription;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final sub = subscription;
    final planName = sub?.plan.name(isArabic: isArabic) ?? '';
    // Defensive: a free plan (tier 0) is a non-renewing trial, so NEVER claim
    // "renews on {date}" / "renews automatically". Post-Tariq a free user at
    // the cap gets SUBSCRIPTION_REQUIRED (→ paywall) and shouldn't reach this
    // sheet at all — this guard just prevents a false renewal claim if the
    // backend behaviour ever changes. Both the renewal pill and the renewal
    // subtitle are gated off for free.
    final isFreePlan = sub?.plan.isFree ?? false;
    final showRenewal = sub != null && sub.hasReliableExpiry && !isFreePlan;
    final renewalDate = showRenewal
        ? DateFormat.yMMMMd(context.locale.toString())
            .format(sub.expiresAt.toLocal())
        : null;

    // title:'' — the visible title sits centered in the body under the hero
    // (matching the mock); the scaffold's chrome keeps the handle + close.
    return QeranBottomSheetScaffold(
      title: '',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s24,
            QeranSpacing.s4,
            QeranSpacing.s24,
            QeranSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: QeranHeroBadge(
                  glyph: Icons.sync_alt,
                  tone: QeranHeroBadgeTone.prominent,
                  size: 96,
                ),
              ),
              QeranSpacing.vs16,
              if (planName.isNotEmpty) ...[
                Center(
                  child: _Pill(
                    icon: Icons.card_membership_rounded,
                    text: LocaleKeys.likes_matches_photo_exchange_limit_plan_badge
                        .tr(namedArgs: {'planName': planName}),
                    background: QeranColors.softFill,
                    iconColor: QeranColors.wine,
                  ),
                ),
                QeranSpacing.vs12,
              ],
              Text(
                LocaleKeys.likes_matches_photo_exchange_limit_title.tr(),
                textAlign: TextAlign.center,
                style: QeranTypography.headline.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w800,
                ),
              ),
              // Renewal subtitle — hidden for a free plan (see isFreePlan note).
              if (!isFreePlan) ...[
                QeranSpacing.vs8,
                Text(
                  LocaleKeys.likes_matches_photo_exchange_limit_subtitle.tr(),
                  textAlign: TextAlign.center,
                  style:
                      QeranTypography.body.copyWith(color: QeranColors.inkBody),
                ),
              ],
              if (renewalDate != null) ...[
                QeranSpacing.vs16,
                Center(
                  child: _Pill(
                    icon: Icons.calendar_today_rounded,
                    text: LocaleKeys.likes_matches_photo_exchange_limit_renewal
                        .tr(namedArgs: {'date': renewalDate}),
                    background: QeranColors.creamSurface,
                    iconColor: QeranColors.goldDeep,
                    shadow: QeranShadows.e1,
                  ),
                ),
              ],
              QeranSpacing.vs24,
              Container(height: 1, color: QeranColors.hairline),
              QeranSpacing.vs20,
              _UpgradeLine(
                text: LocaleKeys
                    .likes_matches_photo_exchange_limit_upgrade_line
                    .tr(),
              ),
            ],
          ),
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s8,
          QeranSpacing.s20,
          QeranSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QeranButton(
              label: LocaleKeys.likes_matches_photo_exchange_limit_cta_upgrade
                  .tr(),
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: onUpgrade,
            ),
            QeranSpacing.vs8,
            QeranButton(
              label: LocaleKeys
                  .likes_matches_photo_exchange_limit_dismiss_later
                  .tr(),
              variant: QeranButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
