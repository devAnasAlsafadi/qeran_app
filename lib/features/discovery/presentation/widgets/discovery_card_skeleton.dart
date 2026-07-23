import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';

/// First-load placeholder that reserves the exact discovery-card geometry.
///
/// The dominant photo region and a few content hints shimmer independently.
/// The widget is isolated behind one repaint boundary and remains vertically
/// scrollable so the parent [RefreshIndicator] keeps working while loading.
class DiscoveryCardSkeleton extends StatelessWidget {
  const DiscoveryCardSkeleton({super.key, this.bottomClearance});

  @visibleForTesting
  static const cardKey = ValueKey<String>('discovery-loading-card');

  /// Override used by focused layout tests. Production derives this from the
  /// floating bottom navigation geometry.
  final double? bottomClearance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final reservedBottom =
            bottomClearance ??
            (QeranBottomNav.contentClearance(context) + 48.0);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: viewportHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ExcludeSemantics(
                        child: RepaintBoundary(
                          child: DecoratedBox(
                            key: cardKey,
                            decoration: BoxDecoration(
                              color: QeranColors.paper,
                              borderRadius: QeranRadii.panelR,
                              border: Border.all(
                                color: QeranColors.wine.withValues(alpha: 0.10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: QeranColors.wine.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const ClipRRect(
                              borderRadius: QeranRadii.panelR,
                              child: _SkeletonCardContent(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: reservedBottom),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCardContent extends StatelessWidget {
  const _SkeletonCardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 51,
          child: LayoutBuilder(
            builder: (context, constraints) =>
                QeranSkeleton.box(height: constraints.maxHeight, radius: 0),
          ),
        ),
        const Expanded(
          flex: 49,
          child: ColoredBox(
            color: QeranColors.paper,
            child: Padding(
              padding: EdgeInsets.all(QeranSpacing.s20),
              child: Column(
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
                  Row(
                    children: [
                      QeranSkeleton(width: 76, height: 28, radius: 999),
                      SizedBox(width: QeranSpacing.s8),
                      QeranSkeleton(width: 92, height: 28, radius: 999),
                      SizedBox(width: QeranSpacing.s8),
                      QeranSkeleton(width: 68, height: 28, radius: 999),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
