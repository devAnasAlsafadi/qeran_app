import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_typography.dart';

/// Tab descriptor for [QeranBottomNav].
class QeranNavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final int? badgeCount;

  const QeranNavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Premium curved-notch bottom navigation. A 56 dp gold disc lifts
/// 24 dp above the bar's top edge at the active tab's center. The bar
/// itself is custom-painted: the top edge dips downward where the
/// disc sits so it reads as a true cutout, not a floating overlay.
///
/// All four moving parts (notch X, disc X, icon swap, haptic) share
/// a single 350 ms easeOutCubic AnimationController so the gesture
/// feels physically coherent.
class QeranBottomNav extends StatefulWidget {
  final List<QeranNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const QeranBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const double totalHeight = 100;
  static const double barHeight = 70;
  static const double discDiameter = 56;
  static const double discLift = 24;

  @override
  State<QeranBottomNav> createState() => _QeranBottomNavState();
}

class _QeranBottomNavState extends State<QeranBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late double _animatedIndex;
  late int _displayedIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animatedIndex = widget.currentIndex.toDouble();
    _displayedIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(QeranBottomNav old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex) {
      final from = _animatedIndex;
      final to = widget.currentIndex.toDouble();
      _ctrl
        ..stop()
        ..reset();
      final tween = Tween<double>(begin: from, end: to)
          .chain(CurveTween(curve: QeranCurves.standard));
      final anim = _ctrl.drive(tween);
      void listener() {
        setState(() => _animatedIndex = anim.value);
      }
      anim.addListener(listener);
      _ctrl.forward().whenComplete(() => anim.removeListener(listener));
      // Icon swap fires ~halfway so the new icon enters as the disc
      // settles on the new tab.
      Future.delayed(const Duration(milliseconds: 175), () {
        if (!mounted) return;
        setState(() => _displayedIndex = widget.currentIndex);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: QeranBottomNav.totalHeight,
        child: LayoutBuilder(
          builder: (context, c) {
            final isRtl = Directionality.of(context) == TextDirection.rtl;
            final count = widget.items.length;
            final tabWidth = c.maxWidth / count;
            final logicalCenter = (_animatedIndex + 0.5) * tabWidth;
            final notchX = isRtl ? c.maxWidth - logicalCenter : logicalCenter;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: QeranBottomNav.barHeight,
                  child: CustomPaint(
                    painter: _NotchedBarPainter(
                      notchCenterX: notchX,
                      notchRadius: QeranBottomNav.discDiameter / 2,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: QeranBottomNav.barHeight,
                  child: Row(
                    children: List.generate(
                      count,
                      (i) => Expanded(
                        child: _TabCell(
                          item: widget.items[i],
                          isActive: i == widget.currentIndex,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (i != widget.currentIndex) widget.onTap(i);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: notchX - QeranBottomNav.discDiameter / 2,
                  bottom: QeranBottomNav.barHeight -
                      QeranBottomNav.discDiameter / 2 +
                      QeranBottomNav.discLift -
                      4,
                  width: QeranBottomNav.discDiameter,
                  height: QeranBottomNav.discDiameter,
                  child: _FloatingDisc(
                    icon: widget.items[_displayedIndex].filledIcon,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;

  _NotchedBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final notchHalf = notchRadius + 10;
    final depth = notchRadius * 1.15;
    const r = 28.0;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(notchCenterX - notchHalf, 0)
      ..cubicTo(
        notchCenterX - notchHalf * 0.40, 0,
        notchCenterX - notchHalf * 0.55, depth,
        notchCenterX, depth,
      )
      ..cubicTo(
        notchCenterX + notchHalf * 0.55, depth,
        notchCenterX + notchHalf * 0.40, 0,
        notchCenterX + notchHalf, 0,
      )
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, QeranColors.wine.withValues(alpha: 0.18), 14, false);
    canvas.drawPath(path, Paint()..color = QeranColors.paper);
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.notchCenterX != notchCenterX || old.notchRadius != notchRadius;
}

class _FloatingDisc extends StatelessWidget {
  final IconData icon;
  const _FloatingDisc({required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold,
        border: Border.all(color: QeranColors.paper, width: 3),
        boxShadow: [
          BoxShadow(
            color: QeranColors.gold.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: QeranColors.wine.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(anim),
            child: child,
          ),
        ),
        child: Icon(
          icon,
          key: ValueKey(icon),
          color: QeranColors.wine,
          size: 28,
        ),
      ),
    );
  }
}

class _TabCell extends StatelessWidget {
  final QeranNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _TabCell({
    required this.item,
    required this.isActive,
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
        radius: 36,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 24,
                child: isActive
                    ? const SizedBox.shrink()
                    : _IconWithBadge(
                        icon: item.outlineIcon,
                        badgeCount: item.badgeCount,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: QeranTypography.caption.copyWith(
                  color: isActive ? QeranColors.wine : QeranColors.inkMuted,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  const _IconWithBadge({required this.icon, required this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount != null && badgeCount! > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: QeranColors.inkMuted, size: 24),
        if (showBadge)
          PositionedDirectional(
            top: -2,
            end: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: QeranColors.gold,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badgeCount! > 9 ? '9+' : '$badgeCount',
                style: QeranTypography.caption.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
