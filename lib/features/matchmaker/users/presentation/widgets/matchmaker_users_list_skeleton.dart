import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';

/// First-load placeholder for a user list: warm-cream shimmer rows that
/// mirror the real card's rhythm — a 52px avatar, two text lines, and the
/// action-bar block (a wide primary + two icon discs).
class MatchmakerUsersListSkeleton extends StatelessWidget {
  const MatchmakerUsersListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s8,
        QeranSpacing.s20,
        QeranSpacing.s20,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: QeranSpacing.s12),
        child: QeranCard(
          padding: EdgeInsets.all(QeranSpacing.s12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  QeranSkeleton.circle(size: 52),
                  QeranSpacing.hs12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QeranSkeleton(width: 140, height: 15),
                        QeranSpacing.vs8,
                        QeranSkeleton(width: 90, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              QeranSpacing.vs12,
              Row(
                children: [
                  Expanded(
                    child: QeranSkeleton.box(
                      height: 40,
                      radius: QeranRadii.control,
                    ),
                  ),
                  QeranSpacing.hs8,
                  QeranSkeleton.circle(size: 40),
                  QeranSpacing.hs8,
                  QeranSkeleton.circle(size: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
