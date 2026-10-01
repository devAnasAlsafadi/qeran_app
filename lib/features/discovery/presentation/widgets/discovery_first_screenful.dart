import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/discovery_profile.dart';
import 'discovery_card.dart';
import 'discovery_merged_profile_body.dart';

/// How fast the empty paper under نبذة عني gives way, per pixel scrolled.
///
/// 1.0 would let the gap merely travel down the page with the content, which
/// is what made it read as dead space; at 2.0 it is spent within about half a
/// flick and the partner sections dock straight under the chips. The photo and
/// نبذة still track the finger exactly — only the gap moves at this rate.
const double _kFoldCollapseRate = 2.0;

/// Leaves a deliberate hint of the next profile section visible when the
/// intro is short, without truncating the complete About Me text.
const double _kNextSectionPeek = 64.0;

/// Photo + نبذة عني, held just short of a full viewport at rest and giving
/// that surplus back as the user scrolls.
///
/// `minHeight` on a `mainAxisSize.min` Column makes the column at least a
/// screen tall while its children still lay out from the top, so the leftover
/// becomes empty paper under نبذة عني — that is what keeps the action buttons
/// off the text while leaving a visible hint of نبذة عن شريك الحياة at the
/// fold. A long نبذة simply grows past it instead of overflowing.
///
/// The surplus is NOT a fixed spacer: it shrinks with the scroll (at
/// [_kFoldCollapseRate]× the scroll distance), so the empty paper closes up
/// instead of travelling down the page ahead of the content. The photo and
/// نبذة still move 1:1 with the finger; only the sections below rise faster,
/// docking flush under the chips once the surplus is spent. From there on
/// everything scrolls normally.
class DiscoveryFirstScreenful extends StatelessWidget {
  const DiscoveryFirstScreenful({
    super.key,
    required this.profile,
    required this.viewportHeight,
    required this.photoHeight,
    required this.scrollOffset,
    required this.pillReveal,
    required this.activeFilterCount,
    this.onFilterTap,
  });

  final DiscoveryProfile profile;

  /// Height of the visible area. At rest the intro reserves this minus
  /// [_kNextSectionPeek], so the next section starts inside the bottom edge.
  final double viewportHeight;

  final double photoHeight;

  /// The card's scroll offset, which spends the surplus under نبذة عني.
  final ValueListenable<double> scrollOffset;

  /// Fades the compatibility pill onto the photo.
  final ValueListenable<double> pillReveal;

  final VoidCallback? onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: QeranColors.paper,
      child: ValueListenableBuilder<double>(
        valueListenable: scrollOffset,
        // The column is built once and passed through — a scroll re-runs the
        // ConstrainedBox only, never the blurred photo.
        builder: (context, offset, child) => ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              viewportHeight -
                  _kNextSectionPeek -
                  offset * _kFoldCollapseRate,
            ),
          ),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The photo is expensive to raster (sigma blur) and it scrolls.
            // Boundaried so scrolling translates a cached layer instead of
            // re-blurring each frame.
            RepaintBoundary(
              child: DiscoveryImagePanel(
                profile: profile,
                height: photoHeight,
                onFilterTap: onFilterTap,
                activeFilterCount: activeFilterCount,
                // The intro sheet slides up over the photo's bottom edge, so
                // the chips have to clear that overlap — plus room to breathe
                // — or the sheet slices through them.
                bottomContentInset:
                    DiscoveryMergedProfileBody.sheetOverlap + QeranSpacing.s16,
                matchPillReveal: pillReveal,
              ),
            ),
            // Transform, not padding: it lifts the sheet over the photo's
            // bottom edge for the layered look without changing the column's
            // height, so the fold maths stays exact.
            Transform.translate(
              offset: const Offset(0, -DiscoveryMergedProfileBody.sheetOverlap),
              child: DiscoveryProfileIntroSheet(profile: profile),
            ),
          ],
        ),
      ),
    );
  }
}
