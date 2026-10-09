part of 'matchmaker_attention_card.dart';

/// The card's content: icon and dot, the count, the label, and the action
/// (or the calm zero line). Sizes to content (no fixed height) so the number,
/// label and affordance always fit — no bottom overflow, and it grows
/// gracefully under large text scale.
class _CardBody extends StatelessWidget {
  const _CardBody({required this.card});

  final MatchmakerAttentionCard card;

  static final _countStyle = QeranTypography.numeric.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: QeranColors.gold,
  );

  static final _labelStyle = QeranTypography.bodySm.copyWith(
    fontWeight: FontWeight.w600,
    color: QeranColors.paper.withValues(alpha: 0.92),
  );

  bool get _urgent => card.count > 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header,
        QeranSpacing.vs12,
        Text('${card.count}', style: _countStyle),
        const SizedBox(height: QeranSpacing.s2),
        Text(
          card.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _labelStyle,
        ),
        QeranSpacing.vs8,
        _action,
      ],
    );
  }

  /// The icon chip, and the urgent dot while there's something to do.
  Widget get _header => Row(
    children: [
      _IconChip(icon: card.icon),
      const Spacer(),
      if (_urgent && card.pulse) const _UrgentDot(),
    ],
  );

  /// The gold action link, or the calm zero line.
  Widget get _action => _urgent
      ? Text(
          card.actionLabel,
          style: QeranTypography.label.copyWith(color: QeranColors.gold),
        )
      : _ZeroPill(label: card.zeroLabel);
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: QeranColors.gold18,
        borderRadius: QeranRadii.controlR,
      ),
      child: Icon(icon, size: 22, color: QeranColors.gold),
    );
  }
}

class _ZeroPill extends StatelessWidget {
  const _ZeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.task_alt_rounded, size: 16, color: QeranColors.gold),
        QeranSpacing.hs4,
        // Flexible + ellipsis so a long zero label (e.g. "لا مراجعات") can
        // never overflow the narrow 2-up hero width.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: QeranTypography.label.copyWith(color: QeranColors.gold),
          ),
        ),
      ],
    );
  }
}

/// Small gold urgent dot with a slow breathing halo.
class _UrgentDot extends StatefulWidget {
  const _UrgentDot();

  @override
  State<_UrgentDot> createState() => _UrgentDotState();
}

class _UrgentDotState extends State<_UrgentDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _dot = SizedBox.square(
    dimension: 8,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [_halo(_c.value), child!],
          ),
          child: _dot,
        ),
      ),
    );
  }

  /// The halo at [t] of its breath: growing from the dot as it fades.
  Widget _halo(double t) => Container(
    width: 8 + 12 * t,
    height: 8 + 12 * t,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: QeranColors.gold.withValues(alpha: 0.28 * (1 - t)),
    ),
  );
}
