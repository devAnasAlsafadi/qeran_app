import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';

/// First-load placeholder for the conversations list: warm-cream shimmer rows
/// mirroring the real card's rhythm (avatar + name line + preview line).
class MatchmakerConversationsListSkeleton extends StatelessWidget {
  const MatchmakerConversationsListSkeleton({super.key, this.rows = 7});

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
          child: Row(
            children: [
              QeranSkeleton.circle(size: 52),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QeranSkeleton(width: 140, height: 16),
                    QeranSpacing.vs8,
                    QeranSkeleton(width: 180, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
