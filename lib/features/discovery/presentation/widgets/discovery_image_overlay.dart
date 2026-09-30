import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../domain/entities/placement_item.dart';
import 'discovery_chips_above_image.dart';
import 'discovery_privacy_message.dart';
import 'discovery_revealing_match_pill.dart';

/// The photo's overlays: the privacy lock and message, and the identity block
/// (name + age, the compatibility pill, the above-image chips). Each region
/// scales down inside its own bounded slot when the height is short (a small
/// device, split screen, or a transient IME), so neither can collide with the
/// other or overflow.
class DiscoveryImageOverlay extends StatelessWidget {
  const DiscoveryImageOverlay({
    super.key,
    required this.name,
    required this.age,
    required this.matchPercent,
    required this.matchPillReveal,
    required this.aboveItems,
    required this.bottomContentInset,
  });

  final String name;
  final int age;
  final double matchPercent;
  final ValueListenable<double>? matchPillReveal;
  final List<PlacementItem> aboveItems;
  final double bottomContentInset;

  static const double _compactHeight = 220;
  static const double _veryCompactHeight = 150;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < _compactHeight;
        final isVeryCompact = constraints.maxHeight < _veryCompactHeight;
        final horizontalPadding = isCompact
            ? QeranSpacing.s12
            : QeranSpacing.s16;
        final topPadding = isCompact ? QeranSpacing.s8 : QeranSpacing.s16;
        // Whichever is larger: the panel's own breathing room, or the space
        // the caller reserved for whatever overlaps the bottom edge.
        final bottomPadding = math.max(
          isCompact ? QeranSpacing.s8 : QeranSpacing.s20,
          bottomContentInset,
        );
        final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
            .clamp(0.0, double.infinity)
            .toDouble();

        final identity = SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _NameAgeRow(name: name, age: age),
              // Compatibility pill — directly under name+age, exactly where
              // the standalone full profile puts it. On the merged screen it
              // is a scroll reveal (see [matchPillReveal]) that takes up NO
              // room until it arrives.
              if (matchPercent > 0)
                DiscoveryRevealingMatchPill(
                  percent: matchPercent,
                  reveal: matchPillReveal,
                  gap: isCompact ? QeranSpacing.s4 : QeranSpacing.s8,
                ),
              SizedBox(height: isCompact ? QeranSpacing.s4 : QeranSpacing.s8),
              DiscoveryChipsAboveImage(items: aboveItems),
            ],
          ),
        );

        // On regular portrait cards the privacy group belongs to the visual
        // center of the whole photo. Previously it occupied the first half of
        // a Column, which made the lock and caption look noticeably too high.
        // Compact landscape/split-screen layouts keep the collision-safe flex
        // arrangement below because the identity block shares very little
        // vertical space with the privacy message there.
        if (!isCompact) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SizedBox(
                    width: contentWidth,
                    child: const DiscoveryPrivacyMessage(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: horizontalPadding,
                  end: horizontalPadding,
                  top: topPadding,
                  bottom: bottomPadding,
                ),
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: identity,
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: horizontalPadding,
            end: horizontalPadding,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isVeryCompact)
                Expanded(
                  flex: isCompact ? 4 : 5,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: contentWidth,
                      child: const DiscoveryPrivacyMessage(),
                    ),
                  ),
                ),
              Expanded(
                flex: isVeryCompact ? 1 : (isCompact ? 6 : 5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.bottomStart,
                  child: identity,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NameAgeRow extends StatelessWidget {
  final String name;
  final int age;

  const _NameAgeRow({required this.name, required this.age});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$name $age',
      style: QeranTypography.headline.copyWith(
        color: QeranColors.paper,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
