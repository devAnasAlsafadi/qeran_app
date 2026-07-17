part of 'plan_selection_widget.dart';

/// The "you are here" free-tier card shown at the top of the packages list for
/// users without an active paid subscription. Private to the
/// [PlanSelectionWidget] library.
class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper.withValues(alpha: 0.6),
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.wine.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: QeranColors.inkMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.subscriptions_free_plan_title.t(context),
                      style: QeranTypography.subtitle.copyWith(
                        color: QeranColors.wine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.subscriptions_price_free.t(context),
                      style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: QeranColors.inkMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  LocaleKeys.subscriptions_badge_you_are_here.t(context),
                  style: QeranTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: QeranColors.inkBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
