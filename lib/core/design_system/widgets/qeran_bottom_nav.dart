import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/bottom_chrome_inset.dart';
import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';
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

/// Premium curved-notch bottom navigation. The bar paints a deep
/// well carved into its top edge, 10 dp wider than the disc, with
/// a cream-coloured cradle fill and a directional wine rim shadow
/// (top of the well only) — recess by colour hierarchy, depth by
/// localised shadow.
///
/// Everything rides ONE 640 ms ease-in-out controller: disc position,
/// notch X, disc icon crossfade, AND each cell's outline icon + label
/// opacity. The whole transition moves as one deliberate motion.
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
  static const double discLift = -7;
  static const double notchRadius = discRadius + 10;
  static const double hMargin = 16;
  static const double bMargin = 16;
  static const double compactLandscapeHeight = 64;
  static const double compactLandscapeMargin = 8;

  /// Bottom inset a tab scrollable needs so its LAST item clears the floating
  /// island + the device gesture area, while items above still scroll under it.
  /// [totalHeight] ≈ bar + bottom margin + breathing; [viewPadding].bottom
  /// re-adds the home-indicator inset the tab body no longer reserves (its
  /// `SafeArea` drops `bottom`). Used as the scrollables' bottom padding.
  static double contentClearance(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.size.width > media.size.height;
    return (isLandscape
            ? compactLandscapeHeight + compactLandscapeMargin
            : totalHeight) +
        media.viewPadding.bottom;
  }

  @override
  State<QeranBottomNav> createState() => _QeranBottomNavState();
}

class _QeranBottomNavState extends State<QeranBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _slide;
  late final CurvedAnimation _iconFade;
  late final ReverseAnimation _slideReverse;

  // Disc position lerps from _animFrom -> _animTo across the curve.
  // Doubles so a rapid mid-animation tap re-anchors from the LIVE
  // interpolated position (no snap-back).
  late double _animFrom;
  late double _animTo;
  late int _iconFrom;
  late int _iconTo;

  // Inactive tabs (not the from/to of any transition) are statically
  // fully visible — share a single const animation.
  static const Animation<double> _staticVisible =
      AlwaysStoppedAnimation<double>(1.0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: QeranMotion.hero, // 640 ms — deliberate, premium
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _slideReverse = ReverseAnimation(_slide);
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

  /// Opacity animation for tab `i`'s outline icon + label.
  /// — i == _iconTo  (becoming active):   1 → 0 across the slide
  /// — i == _iconFrom (becoming inactive): 0 → 1 across the slide
  /// — anything else: statically 1.0
  /// At settled state (controller=1, _iconFrom==_iconTo), the active
  /// tab's _slideReverse evaluates to 0 so its label/icon stay hidden.
  Animation<double> _outlineOpacityFor(int i) {
    if (i == _iconTo) return _slideReverse;
    if (i == _iconFrom) return _slide;
    return _staticVisible;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Declares the nav's own footprint so bottom-anchored overlays (the toast
    // host) sit above it. Wrapped HERE rather than at each shell, so both the
    // user and matchmaker shells get it from the one component, landscape
    // branch included.
    return BottomChromeInset(child: _buildNav(context, media));
  }

  Widget _buildNav(BuildContext context, MediaQueryData media) {
    if (media.size.width > media.size.height) {
      return _CompactLandscapeNav(
        items: widget.items,
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
      );
    }

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
              const discBottom =
                  QeranBottomNav.barHeight +
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
                                outlineOpacity: _outlineOpacityFor(i),
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
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == currentIndex;
                return Expanded(
                  child: Semantics(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? QeranColors.gold20
                                : Colors.transparent,
                            borderRadius: QeranRadii.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IconWithBadge(
                                icon: isActive
                                    ? item.filledIcon
                                    : item.outlineIcon,
                                badgeCount: item.badgeCount,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: QeranTypography.caption.copyWith(
                                    color: isActive
                                        ? QeranColors.wine
                                        : QeranColors.inkMuted,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
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
    final discriminant = (notchRadius * notchRadius - discLift * discLift)
        .clamp(0.0, double.infinity);
    final entryX = discriminant == 0 ? 0.0 : math.sqrt(discriminant);
    const cornerR = QeranRadii.card;

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
        size.width,
        size.height,
        size.width - cornerR,
        size.height,
      )
      ..lineTo(cornerR, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerR)
      ..close();

    // Raised lift so the white island reads clearly above white content
    // (white-on-white needs a stronger, more elevated shadow than e3).
    canvas.drawShadow(
      barPath,
      QeranColors.wine.withValues(alpha: 0.18),
      24,
      false,
    );
    canvas.drawPath(barPath, Paint()..color = QeranColors.paper);

    // Cradle ring = concentric annulus (disc edge → notch edge).
    final discCenter = Offset(notchCenterX, -discLift);
    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: discCenter, radius: notchRadius))
      ..addOval(Rect.fromCircle(center: discCenter, radius: discRadius));

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(cornerR),
      ),
    );

    // Cream fill — the recess reads as a recess by colour hierarchy:
    // bar surface is paper (white, lifted), cradle is creamSurface
    // (warm cream, recessed).
    canvas.drawPath(ringPath, Paint()..color = QeranColors.creamSurface);
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
        radius: 36,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Outline icon + label are always rendered (constant
              // layout); their opacity is driven by `outlineOpacity`
              // so the active tab's content fades synchronously with
              // the disc's slide instead of popping in/out.
              SizedBox(
                height: 24,
                child: FadeTransition(
                  opacity: outlineOpacity,
                  child: _IconWithBadge(
                    icon: item.outlineIcon,
                    badgeCount: item.badgeCount,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: outlineOpacity,
                child: Text(
                  item.label,
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
