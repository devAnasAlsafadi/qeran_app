part of 'plan_selection_widget.dart';

/// The card's mark, at the start of its header: a check on the plan they
/// hold, a radio on the others.
class _PlanMark extends StatelessWidget {
  final bool owned;
  final bool selected;

  const _PlanMark({required this.owned, required this.selected});

  @override
  Widget build(BuildContext context) {
    if (owned) {
      return const Icon(
        Icons.check_circle_rounded,
        color: QeranColors.goldDeep,
        size: 20,
      );
    }
    return Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
      color: selected ? QeranColors.gold : QeranColors.inkMuted,
      size: 20,
    );
  }
}

/// The card's status, at the end of its header: «باقتك الحالية · {period}»
/// on the plan they hold, «ترقية متاحة» on a plan above it (run 11), nothing
/// otherwise.
class _PlanStatus extends StatelessWidget {
  final bool owned;
  final bool upgrade;
  final String? ownedPeriodLabel;

  const _PlanStatus({
    required this.owned,
    required this.upgrade,
    required this.ownedPeriodLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (owned) {
      return _PillBadge(
        label: ownedPlanBadgeLabel(
          LocaleKeys.subscriptions_badge_your_plan.t(context),
          ownedPeriodLabel,
        ),
        background: QeranColors.wine.withValues(alpha: 0.08),
        foreground: QeranColors.wine,
      );
    }
    if (!upgrade) return const SizedBox.shrink();
    return _PillBadge(
      label: LocaleKeys.subscriptions_badge_upgrade_available.t(context),
      background: QeranColors.gold.withValues(alpha: 0.18),
      foreground: QeranColors.goldDeep,
    );
  }
}

/// Rounded status pill used for the plan-card badges (popular tag, "your plan",
/// "upgrade available"). One shape, parameterised on label + colours so the
/// three badges never drift apart.
class _PillBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        label,
        style: QeranTypography.bodySm.copyWith(
          fontSize: fontSize,
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
