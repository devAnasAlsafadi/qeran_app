import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_features.dart';
import '../../domain/entities/subscription_plan.dart';
import '../widgets/purchase_success_hero.dart';
import '../widgets/subscription_entitlement_row.dart';

/// Post-purchase confirmation. The purchased [plan] is passed in from the
/// selection (paid) or the `/subscribe` response (free) — deliberately NOT read
/// from `CurrentSubscriptionCubit`, so this screen is immune to a `/current`
/// outage. A null [plan] (e.g. the restore path) degrades to a dignified
/// title + continue, never a fabricated entitlement list.
class PurchaseSuccessScreen extends StatelessWidget {
  final SubscriptionPlan? plan;

  const PurchaseSuccessScreen({super.key, this.plan});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final planName = plan?.name(isArabic: isArabic) ?? '';

    return Scaffold(
      backgroundColor: QeranColors.paper,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurchaseSuccessHero(planName: planName),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: QeranColors.paper,
                  borderRadius: QeranRadii.domeTop,
                ),
                padding: const EdgeInsets.fromLTRB(
                  QeranSpacing.s20,
                  QeranSpacing.s24,
                  QeranSpacing.s20,
                  QeranSpacing.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (plan != null) ...[
                      _UnlockedHeading(),
                      QeranSpacing.vs12,
                      _EntitlementsCard(features: plan!.features),
                      QeranSpacing.vs24,
                    ],
                    QeranButton(
                      label:
                          LocaleKeys.subscriptions_continue_to_app.t(context),
                      onPressed: () => NavigationManager.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.homeScreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gold-accent "ما فتحته الآن" section label.
class _UnlockedHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: QeranSpacing.s4,
          height: 15,
          decoration: const BoxDecoration(
            borderRadius: QeranRadii.pill,
            color: QeranColors.gold,
          ),
        ),
        QeranSpacing.hs8,
        Text(
          LocaleKeys.subscriptions_purchase_success_unlocked.t(context),
          style: QeranTypography.label.copyWith(color: QeranColors.wine),
        ),
      ],
    );
  }
}

/// The four plan allowances, straight from [features] — unlimited pill for the
/// `-1` sentinel, the raw allowance count otherwise. Nothing fabricated.
class _EntitlementsCard extends StatelessWidget {
  final SubscriptionFeatures features;

  const _EntitlementsCard({required this.features});

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Column(
        children: [
          _row(context, Icons.favorite_rounded,
              LocaleKeys.subscriptions_feature_likes_label.t(context),
              features.likesAllowed),
          _row(context, Icons.handshake_rounded,
              LocaleKeys.subscriptions_feature_serious_interests_label
                  .t(context),
              features.seriousInterestsAllowed),
          _row(context, Icons.photo_library_rounded,
              LocaleKeys.subscriptions_feature_photo_exchanges_label.t(context),
              features.photoExchangesAllowed),
          _row(context, Icons.visibility_rounded,
              LocaleKeys.subscriptions_feature_daily_profile_views_label
                  .t(context),
              features.dailyProfileViewsAllowed),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, int allowed) {
    final unlimited = SubscriptionFeatures.isUnlimited(allowed);
    return SubscriptionEntitlementRow(
      icon: icon,
      label: label,
      unlimited: unlimited,
      valueText: unlimited
          ? LocaleKeys.subscriptions_unlimited.t(context)
          : '$allowed',
    );
  }
}
