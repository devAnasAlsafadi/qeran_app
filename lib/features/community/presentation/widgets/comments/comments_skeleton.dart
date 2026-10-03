import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';
import 'comment_row.dart';

/// Three comment rows' shape while the first page loads (C5): the picture,
/// the name and a line of text.
class CommentsSkeleton extends StatelessWidget {
  const CommentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [_Row(0.7), _Row(0.85), _Row(0.6)]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.share);

  /// The text line's share of the row.
  final double share;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QeranSkeleton.circle(size: CommentRow.avatarSize),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const _Bar(0.3), QeranSpacing.vs8, _Bar(share)],
            ),
          ),
        ],
      ),
    );
  }
}

/// A line of text, [share] of the row's width.
class _Bar extends StatelessWidget {
  const _Bar(this.share);

  final double share;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: share,
      child: const QeranSkeleton(height: 11),
    );
  }
}
