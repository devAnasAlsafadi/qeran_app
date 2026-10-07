import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';

/// Skeleton hero-block height — approximates the live cards' natural
/// (content-sized) height so the loading state matches the loaded layout.
const double _heroHeight = 170;

/// Skeleton shown during the first fetch — mirrors the redesigned layout:
/// a greeting line, a header bar, two tall hero blocks, and four tiles.
/// Warm-cream shimmer (never grey).
class MatchmakerDashboardBodySkeleton extends StatelessWidget {
  const MatchmakerDashboardBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranBottomNav.contentClearance(context),
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            const QeranSkeleton.circle(size: 48),
            QeranSpacing.hs12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const QeranSkeleton(width: 90, height: 10),
                  QeranSpacing.vs8,
                  const QeranSkeleton(width: 150, height: 18),
                ],
              ),
            ),
          ],
        ),
        QeranSpacing.vs24,
        const QeranSkeleton(width: 160, height: 20),
        QeranSpacing.vs12,
        const Row(
          children: [
            Expanded(
              child: QeranSkeleton.box(height: _heroHeight, radius: QeranRadii.panel),
            ),
            QeranSpacing.hs12,
            Expanded(
              child: QeranSkeleton.box(height: _heroHeight, radius: QeranRadii.panel),
            ),
          ],
        ),
        QeranSpacing.vs24,
        const QeranSkeleton(width: 120, height: 20),
        QeranSpacing.vs12,
        GridView.count(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: QeranSpacing.s12,
          crossAxisSpacing: QeranSpacing.s12,
          childAspectRatio: 1.2,
          children: List.generate(
            4,
            (_) => const QeranSkeleton.box(
              height: double.infinity,
              radius: QeranRadii.card,
            ),
            growable: false,
          ),
        ),
      ],
    );
  }
}
