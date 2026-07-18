import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_features.dart';

/// Plan feature list. Prefers the backend's dashboard-controlled display
/// bullets (`featuresAr`/`featuresEn`), so features can change without an app
/// release. Falls back to the numeric checklist built from `plan.features`
/// (still backend data) when no bullets are supplied.
class PlanFeaturesWidget extends StatelessWidget {
  final SubscriptionPlan plan;
  const PlanFeaturesWidget({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final bullets = plan.featureBullets(
      isArabic: context.locale.languageCode == 'ar',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bullets.isNotEmpty
          ? [for (final line in bullets) _BulletRow(text: line)]
          : _numericChecklist(context),
    );
  }

  /// Fallback: the per-metric numeric checklist from `plan.features`.
  List<Widget> _numericChecklist(BuildContext context) {
    final f = plan.features;
    return [
      _FeatureCheckRow(
        label: LocaleKeys.subscriptions_feature_likes_label.t(context),
        value: f.likesAllowed,
      ),
      _FeatureCheckRow(
        label: LocaleKeys.subscriptions_feature_serious_interests_label
            .t(context),
        value: f.seriousInterestsAllowed,
      ),
      _FeatureCheckRow(
        label:
            LocaleKeys.subscriptions_feature_photo_exchanges_label.t(context),
        value: f.photoExchangesAllowed,
      ),
      _FeatureCheckRow(
        label: LocaleKeys.subscriptions_feature_daily_profile_views_label
            .t(context),
        value: f.dailyProfileViewsAllowed,
      ),
    ];
  }
}

/// One backend-supplied bullet: gold check + the line's text. Matches the
/// numeric row's identity, minus the trailing value column (the bullet string
/// is the complete line).
class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: QeranColors.gold,
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              text,
              style: QeranTypography.body.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCheckRow extends StatelessWidget {
  final String label;
  final int value;
  const _FeatureCheckRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isUnlimited = SubscriptionFeatures.isUnlimited(value);
    final valueText = isUnlimited
        ? LocaleKeys.subscriptions_unlimited.t(context)
        : '$value';

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
          Text(
            valueText,
            style: isUnlimited
                ? QeranTypography.bodySm.copyWith(
                    color: QeranColors.goldDeep,
                    fontWeight: FontWeight.bold,
                  )
                : QeranTypography.numeric.copyWith(
                    color: QeranColors.wine,
                  ),
          ),
        ],
      ),
    );
  }
}
