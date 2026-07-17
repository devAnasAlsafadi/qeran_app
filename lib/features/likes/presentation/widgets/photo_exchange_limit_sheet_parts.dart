part of 'photo_exchange_limit_sheet.dart';

/// Icon + label pill. Soft-fill for the plan badge; cream-surface with an
/// `e1` lift for the renewal date.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.background,
    required this.iconColor,
    this.shadow,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color iconColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: QeranRadii.pill,
        boxShadow: shadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          QeranSpacing.hs8,
          Flexible(
            child: Text(
              text,
              style: QeranTypography.bodySm.copyWith(
                color: QeranColors.wine,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold-accented upgrade nudge under the hairline.
class _UpgradeLine extends StatelessWidget {
  const _UpgradeLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          size: 18,
          color: QeranColors.goldDeep,
        ),
        QeranSpacing.hs8,
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: QeranTypography.body.copyWith(
              color: QeranColors.wine,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
