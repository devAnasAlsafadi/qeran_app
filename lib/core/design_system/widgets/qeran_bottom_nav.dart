import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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

/// Premium curved-notch bottom navigation. A 44 dp gold disc nests in
/// a 27 dp-radius socket carved into the bar's top edge. The 5 dp gap
/// between socket and disc is the visible halo — the cradle reads as
/// real carved space, not a flush gold-on-paper join.
///
/// Position (notch X, disc left) and icon cross-fade ride the SAME
/// 420 ms controller, so the socket and disc travel in perfect
/// lockstep and the icon swap is tied to the slide (Interval 0.40-0.85)
/// instead of a wall-clock delay.
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

  static const double totalHeight = 104;
  static const double barHeight = 70;
  static const double discDiameter = 44;

  /// Disc center sits this far ABOVE the bar's flat top edge.
  /// At 2: disc bottom dips 20 dp inside the bar (~45% nested, ~55%
  /// above). Reads as "seated in a socket" rather than "floating".
  static const double discLift = 2;

  /// Socket radius is 5 dp larger than the disc radius. The notch and
  /// the disc are concentric, so the gap is a uniform 5 dp halo around
  /// the disc's perimeter wherever it overlaps the bar — the carve.
  static const double notchRadius = (discDiameter / 2) + 5;

  /// Horizontal screen-edge margin so the bar floats as a card.
  static const double hMargin = 16;

  /// Gap between the bar's bottom edge and the SafeArea bottom.
  static const double bMargin = 12;

  @override
  State<QeranBottomNav> createState() => _QeranBottomNavState();
}

class _QeranBottomNavState extends State<QeranBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _slide;
  late final CurvedAnimation _iconFade;

  // Disc position interpolates from _animFrom -> _animTo. Doubles so a
  // rapid tap mid-animation re-anchors from the LIVE position, not the
  // prior anchor (no snap).
  late double _animFrom;
  late double _animTo;

  // Icon crossfades from _iconFrom (fully shown at slide start) to
  // _iconTo (fully shown when slide settles).
  late int _iconFrom;
  late int _iconTo;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: QeranMotion.gentle, // 420 ms — deliberate, perceptible
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: QeranCurves.standard);
    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.85, curve: Curves.easeInOut),
    );
    _animFrom = widget.currentIndex.toDouble();
    _animTo = widget.currentIndex.toDouble();
    _iconFrom = widget.currentIndex;
    _iconTo = widget.currentIndex;
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(QeranBottomNav old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex) {
      // Snapshot the live interpolated position so a tap during a
      // running animation continues smoothly from where the disc is
      // right now, rather than snapping back to _animFrom.
      final liveT = _slide.value;
      _animFrom = _animFrom + (_animTo - _animFrom) * liveT;
      _animTo = widget.currentIndex.toDouble();
      _iconFrom = _iconTo;
      _iconTo = widget.currentIndex;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _iconFade.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranBottomNav.hMargin,
          0,
          QeranBottomNav.hMargin,
          QeranBottomNav.bMargin,
        ),
        child: SizedBox(
          height: QeranBottomNav.totalHeight,
          child: LayoutBuilder(
            builder: (context, c) {
              final isRtl = Directionality.of(context) == TextDirection.rtl;
              final count = widget.items.length;
              final tabWidth = c.maxWidth / count;
              const discBottom = QeranBottomNav.barHeight +
                  QeranBottomNav.discLift -
                  QeranBottomNav.discDiameter / 2;
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _slide.value;
                  final animIndex =
                      lerpDouble(_animFrom, _animTo, t) ?? _animTo;
                  final logicalCenter = (animIndex + 0.5) * tabWidth;
                  final notchX =
                      isRtl ? c.maxWidth - logicalCenter : logicalCenter;
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
                            notchRadius: QeranBottomNav.notchRadius,
                            discLift: QeranBottomNav.discLift,
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
                                  if (i != widget.currentIndex) {
                                    widget.onTap(i);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: notchX - QeranBottomNav.discDiameter / 2,
                        bottom: discBottom,
                        width: QeranBottomNav.discDiameter,
                        height: QeranBottomNav.discDiameter,
                        child: _FloatingDisc(
                          fromIcon: widget.items[_iconFrom].filledIcon,
                          toIcon: widget.items[_iconTo].filledIcon,
                          fade: _iconFade,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;
  final double discLift;

  _NotchedBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
    required this.discLift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Notch = circle centered at the disc's center (notchCenterX,
    // -discLift) with radius `notchRadius`. Bar's paper edge follows
    // this larger circle, leaving a uniform `notchRadius - discRadius`
    // halo of page/cream-canvas around the disc.
    //
    // Entry/exit X (where the notch circle crosses y=0):
    //     x = ±sqrt(notchRadius² - discLift²)
    //
    // arcToPoint with clockwise:false picks the lower arc of the notch
    // circle (the one that dips DOWN into the bar in y-down canvas).
    final discriminant = (notchRadius * notchRadius - discLift * discLift)
        .clamp(0.0, double.infinity);
    final entryX = discriminant == 0 ? 0.0 : math.sqrt(discriminant);
    const r = 28.0;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(notchCenterX - entryX, 0)
      ..arcToPoint(
        Offset(notchCenterX + entryX, 0),
        radius: Radius.circular(notchRadius),
        clockwise: false,
        largeArc: false,
      )
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..close();

    canvas.drawShadow(
      path,
      QeranColors.wine.withValues(alpha: 0.22),
      22,
      false,
    );
    canvas.drawPath(path, Paint()..color = QeranColors.paper);
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.notchCenterX != notchCenterX ||
      old.notchRadius != notchRadius ||
      old.discLift != discLift;
}

class _FloatingDisc extends StatelessWidget {
  final IconData fromIcon;
  final IconData toIcon;
  final Animation<double> fade;

  const _FloatingDisc({
    required this.fromIcon,
    required this.toIcon,
    required this.fade,
  });

  @override
  Widget build(BuildContext context) {
    // 1.5 dp wine ring frames the gold body. Gold shadow blur dropped
    // 10 -> 6 so the soft halo doesn't bleed across the 5 dp paper
    // cradle and dilute the carved feel.
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold,
        border: Border.all(color: QeranColors.wine, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: QeranColors.gold.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: QeranColors.wine.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: ReverseAnimation(fade),
              child: Icon(fromIcon, color: QeranColors.wine, size: 22),
            ),
            FadeTransition(
              opacity: fade,
              child: Icon(toIcon, color: QeranColors.wine, size: 22),
            ),
          ],
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
