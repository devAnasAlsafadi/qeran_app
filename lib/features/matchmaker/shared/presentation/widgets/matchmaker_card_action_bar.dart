import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import 'matchmaker_icon_action.dart';

/// One card's primary action — a gold [QeranButton] (wine label).
class MatchmakerPrimaryAction {
  const MatchmakerPrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
}

/// One card's secondary action — an icon-only [MatchmakerIconAction] disc.
class MatchmakerSecondaryAction {
  const MatchmakerSecondaryAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool loading;
}

/// The reusable card action pattern: a dominant gold primary that flexes to
/// fill the row, trailed by tidy icon-only wine-06 secondaries. Mirrors
/// automatically (RTL/LTR) — the primary leads the start edge, secondaries
/// trail the end. Shared across the matchmaker cards (Users now; Cases /
/// Explore / Conversations later) so the affordance never diverges.
class MatchmakerCardActionBar extends StatelessWidget {
  const MatchmakerCardActionBar({
    super.key,
    required this.primary,
    this.secondaries = const [],
  });

  final MatchmakerPrimaryAction primary;
  final List<MatchmakerSecondaryAction> secondaries;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QeranButton(
            label: primary.label,
            leadingIcon: primary.icon,
            onPressed: primary.onTap,
            variant: QeranButtonVariant.primary,
            size: QeranButtonSize.xs,
            loading: primary.loading,
          ),
        ),
        for (final s in secondaries) ...[
          QeranSpacing.hs8,
          MatchmakerIconAction(
            icon: s.icon,
            onTap: s.onTap,
            tooltip: s.tooltip,
            loading: s.loading,
          ),
        ],
      ],
    );
  }
}
