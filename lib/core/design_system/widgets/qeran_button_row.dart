import 'package:flutter/material.dart';

import '../tokens/qeran_spacing.dart';

/// Buttons side by side, sharing the width equally and the tallest one's
/// height. A label that wraps onto a second line grows its button (run 6);
/// its partner grows with it rather than sitting short and centred beside it.
class QeranButtonRow extends StatelessWidget {
  const QeranButtonRow({
    super.key,
    required this.children,
    this.gap = QeranSpacing.s12,
  });

  /// Usually two `QeranButton`s, in reading order.
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
