part of 'packages_screen.dart';

/// A VIP owner's plans screen: a celebration in place of the plans. Its rows
/// say what the plan gives, from its `features{}` (run 10): unlimited or the
/// number.
class _VipCelebratingWidget extends StatelessWidget {
  const _VipCelebratingWidget({required this.features});

  final SubscriptionFeatures features;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.eHero,
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.cardR,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [QeranColors.wineLight, QeranColors.wine],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: QeranColors.gold.withValues(alpha: 0.18),
                      border: Border.all(color: QeranColors.gold, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: QeranColors.gold,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    LocaleKeys.subscriptions_vip_celebrate_subtitle.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.headline.copyWith(
                      color: QeranColors.paper,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.subscriptions_vip_celebrate_body.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.bodySm.copyWith(
                      color: QeranColors.gold.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: QeranColors.gold,
                        ),
                      ),
                      QeranSpacing.hs8,
                      Text(
                        LocaleKeys.subscriptions_vip_active_features.t(context),
                        style: QeranTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: QeranColors.wine,
                        ),
                      ),
                    ],
                  ),
                  QeranSpacing.vs12,
                  _CelebratingFeatureRow(
                    label: LocaleKeys.subscriptions_feature_likes_label.t(
                      context,
                    ),
                    allowed: features.likesAllowed,
                  ),
                  _CelebratingFeatureRow(
                    label: LocaleKeys
                        .subscriptions_feature_photo_exchanges_label
                        .t(context),
                    allowed: features.photoExchangesAllowed,
                  ),
                  _CelebratingFeatureRow(
                    label: LocaleKeys
                        .subscriptions_feature_daily_profile_views_label
                        .t(context),
                    allowed: features.dailyProfileViewsAllowed,
                  ),
                  const SizedBox(height: 28),
                  QeranButton(
                    label: LocaleKeys.subscriptions_vip_back_to_profile.t(
                      context,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebratingFeatureRow extends StatelessWidget {
  final String label;

  /// The plan's allowance: `-1` is unlimited.
  final int allowed;
  const _CelebratingFeatureRow({required this.label, required this.allowed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          if (!SubscriptionFeatures.isUnlimited(allowed))
            Text(
              '$allowed',
              style: QeranTypography.numeric.copyWith(color: QeranColors.wine),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.all_inclusive_rounded,
                  size: 17,
                  color: QeranColors.goldDeep,
                ),
                QeranSpacing.hs4,
                Text(
                  LocaleKeys.subscriptions_unlimited.t(context),
                  style: QeranTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: QeranColors.goldDeep,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
