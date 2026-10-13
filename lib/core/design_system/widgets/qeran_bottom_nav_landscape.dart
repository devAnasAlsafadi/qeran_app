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
          decoration: BoxDecoration(
            color: QeranColors.paper,
            borderRadius: QeranRadii.cardR,
            boxShadow: [
              BoxShadow(
                color: QeranColors.wine.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
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
        child: Center(
          child: AnimatedContainer(
            duration: QeranMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? QeranColors.gold20 : Colors.transparent,
              borderRadius: QeranRadii.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconWithBadge(
                  item: item,
                  icon: isActive
                      ? _NavGlyph.filled(item, QeranColors.inkMuted)
                      : _NavGlyph.outline(item, QeranColors.inkMuted),
                ),
                const SizedBox(width: 6),
                Flexible(child: _label(item, isActive)),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
