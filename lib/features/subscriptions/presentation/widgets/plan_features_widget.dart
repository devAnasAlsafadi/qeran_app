import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/helpers/subscription_format.dart';

/// Feature checklist derived from `plan.features` — the numeric counts (likes /
/// serious interests / photo exchanges / daily views) come from the backend
/// and are never hardcoded. Each row is a gold check + a wine label.
class PlanFeaturesWidget extends StatelessWidget {
  final SubscriptionPlan plan;
  const PlanFeaturesWidget({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final f = plan.features;
    final items = <String>[
      SubscriptionFormat.formatAllowed(
        context,
        f.likesAllowed,
        LocaleKeys.subscriptions_feature_likes.t(context),
      ),
      SubscriptionFormat.formatAllowed(
        context,
        f.seriousInterestsAllowed,
        LocaleKeys.subscriptions_feature_serious_interests.t(context),
      ),
      SubscriptionFormat.formatAllowed(
        context,
        f.photoExchangesAllowed,
        LocaleKeys.subscriptions_feature_photo_exchanges.t(context),
      ),
      SubscriptionFormat.formatAllowed(
        context,
        f.dailyProfileViewsAllowed,
        LocaleKeys.subscriptions_feature_daily_profile_views.t(context),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final label in items) _FeatureCheckRow(label: label)],
    );
  }
}

class _FeatureCheckRow extends StatelessWidget {
  final String label;
  const _FeatureCheckRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: QeranColors.gold,
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              label,
              style: QeranTypography.body.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}
