part of 'qeran_bottom_nav.dart';

class _CompactLandscapeNav extends StatelessWidget {
  const _CompactLandscapeNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<QeranNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranBottomNav.hMargin,
          0,
          QeranBottomNav.hMargin,
          QeranBottomNav.compactLandscapeMargin,
        ),
        child: DecoratedBox(
          key: QeranBottomNav.barKey,
          decoration: BoxDecoration(
            color: QeranColors.paper,
            borderRadius: QeranRadii.cardR,
            // The portrait island's lift and hairline (run 11).
            boxShadow: QeranShadows.eLiftUp,
            border: Border.all(
              color: QeranShadows.hairlineBorder,
              width: QeranStrokes.hairline,
            ),
          ),
          child: SizedBox(
            height: QeranBottomNav.compactLandscapeHeight,
            child: Row(
              children: List.generate(
                items.length,
                (index) => Expanded(child: _tab(index)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index) {
    final item = items[index];
    final isActive = index == currentIndex;
    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: InkWell(
        borderRadius: QeranRadii.pill,
        onTap: isActive
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap(index);
              },
        // Inset, so a long label never pushes the disc to the bar's edge.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _disc(item, isActive),
                const SizedBox(width: 6),
                Flexible(child: _label(item, isActive)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The portrait bar's mark, the same here (run 8): a gold disc inside the
  /// bar behind the selected tab's filled wine icon. It fades in and out in
  /// place, as the pill it replaced did.
  Widget _disc(QeranNavItem item, bool isActive) => AnimatedContainer(
    duration: QeranMotion.standard,
    width: QeranBottomNav.discDiameter,
    height: QeranBottomNav.discDiameter,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: QeranColors.gold.withValues(alpha: isActive ? 1 : 0),
    ),
    child: _IconWithBadge(
      item: item,
      icon: isActive
          ? _NavGlyph.filled(item, QeranColors.wine)
          : _NavGlyph.outline(item, QeranColors.inkMuted),
    ),
  );

  Widget _label(QeranNavItem item, bool isActive) => Text(
    item.label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: QeranTypography.caption.copyWith(
      color: isActive ? QeranColors.wine : QeranColors.inkMuted,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
    ),
  );
}
