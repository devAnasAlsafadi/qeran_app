import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';

/// First-load placeholder for the cases list: warm-cream shimmer cards that
/// mirror the real case card's rhythm (a status pill above two avatars with
/// names).
class MatchmakerCasesListSkeleton extends StatelessWidget {
  const MatchmakerCasesListSkeleton({super.key, this.cards = 5});

  final int cards;

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
      itemCount: cards,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: QeranSpacing.s12),
        child: QeranCard(
          padding: EdgeInsets.all(QeranSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              QeranSkeleton(width: 120, height: 22, radius: 999),
              QeranSpacing.vs16,
              Row(
                children: [
                  Expanded(child: _PersonSkeleton()),
                  QeranSpacing.hs8,
                  Expanded(child: _PersonSkeleton()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonSkeleton extends StatelessWidget {
  const _PersonSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QeranSkeleton.circle(size: 56),
        QeranSpacing.vs8,
        QeranSkeleton(width: 70, height: 14),
      ],
    );
  }
}
