import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';

/// First-load placeholder for the merged discovery screen.
///
/// Mirrors the loaded geometry exactly: a full-bleed photo block as tall as the
/// loaded photo ([discoveryPhotoHeight]), then the نبذة عني sheet running edge
/// to edge. It
/// used to draw a floating rounded card with 18dp side margins and a shadow,
/// which is what the screen looked like BEFORE the merge — so the shimmer
/// promised one layout and the loaded state delivered another.
///
/// Stays vertically scrollable so the parent [RefreshIndicator] keeps working
/// while loading.
class DiscoveryCardSkeleton extends StatelessWidget {
  const DiscoveryCardSkeleton({super.key, this.photoFraction});

  @visibleForTesting
  static const cardKey = ValueKey<String>('discovery-loading-card');

  /// Override used by focused layout tests. Production matches the loaded
  /// screen's own fraction.
  final double? photoFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final photoHeight = photoFraction == null
            ? discoveryPhotoHeight(
                context,
                viewportHeight: viewportHeight,
                isLandscape: isLandscape,
              )
            : viewportHeight * photoFraction!;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: SizedBox(
                key: cardKey,
                height: viewportHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full-bleed photo block — no side margins, no radius, no
                    // shadow. Same shape the real photo takes.
                    QeranSkeleton.box(height: photoHeight, radius: 0),
                    Expanded(
                      child: _SkeletonSheet(isLandscape: isLandscape),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fraction of the viewport the discovery photo occupies. Shared so the
/// shimmer and the loaded card can never drift apart.
const double kDiscoveryPhotoFraction = 0.50;
const double kDiscoveryPhotoFractionLandscape = 0.45;

/// The photo's height on a small phone held upright: a screen this tall or
/// less (an iPhone SE is 667) gets a fixed photo instead of half the viewport.
const double kDiscoveryPhotoHeightSmall = 280;
const double kDiscoveryPhotoSmallScreenMaxHeight = 700;

/// The discovery photo's height, for the shimmer and the loaded card alike.
double discoveryPhotoHeight(
  BuildContext context, {
  required double viewportHeight,
  required bool isLandscape,
}) {
  if (isLandscape) return viewportHeight * kDiscoveryPhotoFractionLandscape;
  final screenHeight = MediaQuery.sizeOf(context).height;
  if (screenHeight <= kDiscoveryPhotoSmallScreenMaxHeight) {
    return kDiscoveryPhotoHeightSmall;
  }
  return viewportHeight * kDiscoveryPhotoFraction;
}

/// The نبذة عني sheet placeholder: full width, rounded top only, paper fill.
class _SkeletonSheet extends StatelessWidget {
  const _SkeletonSheet({required this.isLandscape});

  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QeranRadii.panel),
        ),
      ),
      padding: EdgeInsets.all(
        isLandscape ? QeranSpacing.s12 : QeranSpacing.s20,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QeranSkeleton(width: 156, height: 20),
          SizedBox(height: QeranSpacing.s16),
          QeranSkeleton(height: 12),
          SizedBox(height: QeranSpacing.s8),
          FractionallySizedBox(
            widthFactor: 0.72,
            alignment: AlignmentDirectional.centerStart,
            child: QeranSkeleton(height: 12),
          ),
          SizedBox(height: QeranSpacing.s20),
          Wrap(
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s8,
            children: [
              QeranSkeleton(width: 76, height: 28, radius: 999),
              QeranSkeleton(width: 92, height: 28, radius: 999),
              QeranSkeleton(width: 68, height: 28, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}
