import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';

import 'subscription_activating_notice.dart';

/// Paid, and the server hasn't confirmed it yet (C5): the card on «اشتراكي»,
/// and at the top of the plans, so nobody buys again thinking it failed.
class SubscriptionActivatingCard extends StatelessWidget {
  const SubscriptionActivatingCard({super.key, required this.overdue});

  final bool overdue;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: QeranColors.goldDeep,
            size: 22,
          ),
          QeranSpacing.hs12,
          Expanded(child: SubscriptionActivatingNotice(overdue: overdue)),
        ],
      ),
    );
  }
}
