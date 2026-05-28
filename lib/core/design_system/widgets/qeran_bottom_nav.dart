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

/// Premium curved-notch bottom navigation. The bar paints a DEEP well
/// (notch depth ~39 dp into a 70 dp bar) sized 10 dp wider than the
/// disc, so the disc visibly nests with a paper-coloured ring around
/// it. A wine-tinted vertical gradient inside that ring sells the
/// depth — the rim casts shadow down into the well.
///
/// The active tab's label is hidden (the disc takes its place). The
/// disc, the notch and the icon cross-fade all ride a single 420 ms
/// controller, so the cradle drags the disc across the bar in
/// lockstep.
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
  static const double discRadius = discDiameter / 2;

  /// Disc center offset relative to bar's flat top (positive = above,
  /// negative = below). At -7: disc center is 7 dp INSIDE the bar →
  /// disc bottom dips 29 dp below bar top, disc top crowns 15 dp
  /// above (~34% peek, ~66% submerged).
  static const double discLift = -7;

  /// Socket radius = disc radius + 10 dp gap. The 10 dp halo around
  /// the disc is the visible cradle space.
  static const double notchRadius = discRadius + 10;

  static const double hMargin = 16;
  static const double bMargin = 12;

  @override
  State<QeranBottomNav> createState() => _QeranBottomNavState();
}

class _QeranBottomNavState extends State<QeranBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _slide;
  late final CurvedAnimation _iconFade;

  // Disc position lerps from _animFrom -> _animTo across the curve.
  // Doubles so a rapid mid-animation tap re-anchors from the live
  // interpolated position (no snap-back).
  late double _animFrom;
  late double _animTo;

  // Icon crossfades from _iconFrom (visible at t=0) to _iconTo
  // (visible at t=1) over the controller's [0.40, 0.85] interval.
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
                  QeranBottomNav.discRadius;
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _slide.value;
                  final animIndex =
                      lerpDouble(_animFrom, _animTo, t) ?? _animTo;
                  final logicalCenter = (animIndex + 0.5) * tabWidth;
                  final notchX = isRtl
                      ? c.maxWidth - logicalCenter
                      : logicalCenter;
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
                            discRadius: QeranBottomNav.discRadius,
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
                        left: notchX - QeranBottomNav.discRadius,
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
  final double discRadius;
  final double discLift;

  _NotchedBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
    required this.discRadius,
    required this.discLift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Painter coords: y=0 at bar top edge, y=size.height at bar bottom.
    // Disc & notch are concentric at (notchCenterX, -discLift).

    final discriminant = (notchRadius * notchRadius - discLift * discLift)
        .clamp(0.0, double.infinity);
    final entryX = discriminant == 0 ? 0.0 : math.sqrt(discriminant);
    const cornerR = 28.0;

    // Bar outline with the wide cradle carved into the top.
    // arcToPoint clockwise:false picks the lower arc — dips DOWN into
    // the bar (canvas y is down).
    final barPath = Path()
      ..moveTo(0, cornerR)
      ..quadraticBezierTo(0, 0, cornerR, 0)
      ..lineTo(notchCenterX - entryX, 0)
      ..arcToPoint(
        Offset(notchCenterX + entryX, 0),
        radius: Radius.circular(notchRadius),
        clockwise: false,
        largeArc: false,
      )
      ..lineTo(size.width - cornerR, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerR)
      ..lineTo(size.width, size.height - cornerR)
      ..quadraticBezierTo(
          size.width, size.height, size.width - cornerR, size.height)
      ..lineTo(cornerR, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerR)
      ..close();

    canvas.drawShadow(
      barPath,
      QeranColors.wine.withValues(alpha: 0.22),
      22,
      false,
    );
    canvas.drawPath(barPath, Paint()..color = QeranColors.paper);

    // Cradle ring = annulus between disc circle (r=discRadius) and
    // notch circle (r=notchRadius), concentric at the disc center.
    // Painted paper-coloured first so the cradle is a tangible recess
    // (not a transparent halo showing page content), then overlaid
    // with a wine-tinted vertical gradient — darkest at the rim,
    // fading toward the bottom of the well. This is the depth cue.
    final discCenter = Offset(notchCenterX, -discLift);
    final outerOval = Rect.fromCircle(center: discCenter, radius: notchRadius);
    final innerOval = Rect.fromCircle(center: discCenter, radius: discRadius);
    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(outerOval)
      ..addOval(innerOval);

    canvas.save();
    // Clip to the bar's outer silhouette so the ring never bleeds
    // past the floating bar's rounded edges (important for first/last
    // tabs, where the cradle sits close to a corner).
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(cornerR),
    ));

    canvas.drawPath(ringPath, Paint()..color = QeranColors.paper);

    final shadowRect = Rect.fromLTRB(
      notchCenterX - notchRadius,
      0,
      notchCenterX + notchRadius,
      -discLift + notchRadius,
    );
    final shadow = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        QeranColors.wine.withValues(alpha: 0.55),
        QeranColors.wine.withValues(alpha: 0.18),
        QeranColors.wine.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(
      ringPath,
      Paint()..shader = shadow.createShader(shadowRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.notchCenterX != notchCenterX ||
      old.notchRadius != notchRadius ||
      old.discRadius != discRadius ||
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
    // 2.5 dp paper (white) ring separates the gold body cleanly from
    // the wine-shadowed cradle interior. Disc shadows kept softened
    // so the gold glow doesn't dilute the wine well.
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold,
        border: Border.all(color: QeranColors.paper, width: 2.5),
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
              // Active tab's label is hidden — the disc takes its
              // place. Inactive tabs keep icon + label.
              if (!isActive)
                Text(
                  item.label,
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.inkMuted,
                    fontWeight: FontWeight.w500,
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
