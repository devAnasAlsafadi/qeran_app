import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_features.dart';
import '../../domain/helpers/subscription_format.dart';

/// Lists the four feature allowances the user unlocks with the
/// selected plan. Renders "غير محدود" for the unlimited sentinel —
/// never the raw `-1`.
class CheckoutFeaturesCard extends StatelessWidget {
  final SubscriptionFeatures features;
  const CheckoutFeaturesCard({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final rows = _rows(context);
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.subscriptions_checkout_features_title.t(context),
            style: QeranTypography.subtitle.copyWith(
              color: QeranColors.wine,
            ),
          ),
          const SizedBox(height: QeranSpacing.s12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: QeranSpacing.s8),
            _FeatureRow(text: rows[i]),
          ],
        ],
      ),
    );
  }

  /// One localized line per allowance — `label: count unit`, or
  /// `label: unlimited` for the `-1` sentinel. Reuses the same feature keys +
  /// [SubscriptionFormat] as the plan card so wording stays consistent.
  List<String> _rows(BuildContext context) {
    String line(String label, String noun, int value) =>
        '$label: ${SubscriptionFormat.formatAllowed(context, value, noun)}';
    return <String>[
      line(
        LocaleKeys.subscriptions_feature_likes_label.t(context),
        LocaleKeys.subscriptions_feature_likes.t(context),
        features.likesAllowed,
      ),
      line(
        LocaleKeys.subscriptions_feature_serious_interests_label.t(context),
        LocaleKeys.subscriptions_feature_serious_interests.t(context),
        features.seriousInterestsAllowed,
      ),
      line(
        LocaleKeys.subscriptions_feature_photo_exchanges_label.t(context),
        LocaleKeys.subscriptions_feature_photo_exchanges.t(context),
        features.photoExchangesAllowed,
      ),
      line(
        LocaleKeys.subscriptions_feature_daily_profile_views_label.t(context),
        LocaleKeys.subscriptions_feature_daily_profile_views.t(context),
        features.dailyProfileViewsAllowed,
      ),
    ];
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: QeranColors.gold,
          size: 18,
        ),
        const SizedBox(width: QeranSpacing.s8),
        Expanded(
          child: Text(
            text,
            style: QeranTypography.body.copyWith(color: QeranColors.wine),
          ),
        ),
      ],
    );
  }
}
