import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';

/// Loading placeholder for a chat thread — cream/gold shimmer bubbles with
/// alternating alignment and width, so the wait reads as "messages loading"
/// rather than a bare spinner. Never grey.
class ChatMessageSkeleton extends StatelessWidget {
  const ChatMessageSkeleton({super.key});

  // (isMine, widthFraction, height) — a natural back-and-forth rhythm.
  static const List<({bool mine, double frac, double height})> _rows = [
    (mine: false, frac: 0.52, height: 40),
    (mine: true, frac: 0.42, height: 40),
    (mine: false, frac: 0.68, height: 58),
    (mine: true, frac: 0.6, height: 40),
    (mine: false, frac: 0.38, height: 40),
    (mine: true, frac: 0.7, height: 58),
  ];

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s12,
      ),
      children: [
        for (final r in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s6),
            child: Align(
              alignment: r.mine
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: QeranSkeleton.box(
                width: maxWidth * r.frac,
                height: r.height,
                radius: 16,
              ),
            ),
          ),
      ],
    );
  }
}
