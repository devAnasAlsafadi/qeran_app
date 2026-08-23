import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_spacing.dart';

enum QeranCardVariant { standard, hero, flat }

/// Default elevated card. Use [QeranCard.hero] for paywall / match-success
/// surfaces, [QeranCard.flat] inside already-elevated parents.
class QeranCard extends StatelessWidget {
  const QeranCard({
    super.key,
    required this.child,
    this.variant = QeranCardVariant.standard,
    this.padding,
    this.margin,
    this.accentBar = false,
    this.onTap,
    this.background,
  });

  const QeranCard.hero({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.accentBar = true,
    this.onTap,
    this.background,
  }) : variant = QeranCardVariant.hero;

  const QeranCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.background,
  })  : variant = QeranCardVariant.flat,
        accentBar = false;

  final Widget child;
  final QeranCardVariant variant;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool accentBar;
  final VoidCallback? onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final radius = _radius(variant);
    final shadow = _shadow(variant);
    final pad = padding ??
        (variant == QeranCardVariant.hero
            ? QeranSpacing.cardInnerHero
            : QeranSpacing.cardInner);
    final bg = background ?? QeranColors.paper;

    final content = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          if (accentBar)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _AccentBar(),
            ),
          Padding(padding: pad, child: child),
        ],
      ),
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: shadow,
        border: variant == QeranCardVariant.flat
            ? Border.all(color: QeranColors.wine08)
            : null,
      ),
      child: content,
    );

    final tappable = onTap == null
        ? decorated
        : Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              splashColor: QeranColors.wine08,
              highlightColor: QeranColors.wine06,
              child: decorated,
            ),
          );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: tappable,
    );
  }

  static BorderRadius _radius(QeranCardVariant v) => switch (v) {
        QeranCardVariant.standard => QeranRadii.cardR,
        QeranCardVariant.hero => QeranRadii.panelR,
        QeranCardVariant.flat => QeranRadii.cardR,
      };

  static List<BoxShadow> _shadow(QeranCardVariant v) => switch (v) {
        QeranCardVariant.standard => QeranShadows.e2,
        QeranCardVariant.hero => QeranShadows.e3,
        QeranCardVariant.flat => QeranShadows.e0,
      };
}

class _AccentBar extends StatelessWidget {
  const _AccentBar();

  @override
  Widget build(BuildContext context) {
    return Container(height: 3, color: QeranColors.gold);
  }
}
