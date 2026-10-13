part of 'qeran_bottom_nav.dart';

/// The size every nav icon draws at, outline or filled, in either layout.
const double _iconSize = 29;

/// One tab: its icon in a disc-sized slot at a fixed height, so the disc
/// lands on it exactly, and its label under it — always shown.
class _TabCell extends StatelessWidget {
  final QeranNavItem item;
  final bool isActive;
  final Animation<double> outlineOpacity;
  final VoidCallback onTap;

  const _TabCell({
    required this.item,
    required this.isActive,
    required this.outlineOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 43,
        child: Column(
          children: [
            const SizedBox(height: QeranBottomNav.iconSlotTop),
            SizedBox.square(
              dimension: QeranBottomNav.discDiameter,
              child: Center(child: _CellIcon(item, outlineOpacity)),
            ),
            const SizedBox(height: 2),
            Flexible(child: _cellLabel()),
          ],
        ),
      ),
    );
  }

  /// Wine and bold when selected, muted otherwise; the colour follows the
  /// icon's crossfade.
  Widget _cellLabel() => AnimatedBuilder(
    animation: outlineOpacity,
    builder: (context, _) => Text(
      item.label,
      style: QeranTypography.caption.copyWith(
        color: Color.lerp(
          QeranColors.wine,
          QeranColors.inkMuted,
          outlineOpacity.value,
        ),
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// The outline icon (muted) and the filled one (wine), crossfaded: the filled
/// one shows when the disc is under it.
class _CellIcon extends StatelessWidget {
  const _CellIcon(this.item, this.outlineOpacity);

  final QeranNavItem item;
  final Animation<double> outlineOpacity;

  @override
  Widget build(BuildContext context) {
    return _IconWithBadge(
      item: item,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: outlineOpacity,
            child: Icon(
              item.outlineIcon,
              color: QeranColors.inkMuted,
              size: _iconSize,
            ),
          ),
          FadeTransition(
            opacity: ReverseAnimation(outlineOpacity),
            child: Icon(
              item.filledIcon,
              color: QeranColors.wine,
              size: _iconSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// [icon] with [item]'s badge on its top end corner.
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({required this.item, required this.icon});

  final QeranNavItem item;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final count = item.badgeCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (count != null && count > 0)
          PositionedDirectional(
            top: -2,
            end: -4,
            child: _Badge(
              count: count,
              isDot: item.badgeIsDot,
              color: item.badgeColor,
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.isDot, required this.color});

  final int count;
  final bool isDot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (isDot) {
      return Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: QeranColors.paper, width: 1.5),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: QeranTypography.caption.copyWith(
          color: QeranColors.wine,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
