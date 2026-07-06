import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The mediation flow as three status rows inside the matchmaker glass card:
/// inquiry sent → response received → families' details. Each row is a square
/// gold-icon tile + label + a gold status chip, on the card's dark glass.
class OnboardingMediationBlocks extends StatelessWidget {
  const OnboardingMediationBlocks({super.key});

  @override
  Widget build(BuildContext context) {
    final blocks = <_BlockData>[
      _BlockData(
        Icons.send_rounded,
        LocaleKeys.onboarding_mediation_block_sent_label.t(context),
        LocaleKeys.onboarding_mediation_block_sent_status.t(context),
        Icons.check_circle_rounded,
      ),
      _BlockData(
        Icons.mark_email_read_rounded,
        LocaleKeys.onboarding_mediation_block_response_label.t(context),
        LocaleKeys.onboarding_mediation_block_response_status.t(context),
        Icons.mark_email_read_rounded,
      ),
      _BlockData(
        Icons.diversity_3_rounded,
        LocaleKeys.onboarding_mediation_block_families_label.t(context),
        LocaleKeys.onboarding_mediation_block_families_status.t(context),
        Icons.schedule_rounded,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) QeranSpacing.vs12,
          _StatusRow(data: blocks[i]),
        ],
      ],
    );
  }
}

class _BlockData {
  final IconData icon;
  final String label;
  final String status;
  final IconData chipIcon;
  const _BlockData(this.icon, this.label, this.status, this.chipIcon);
}

class _StatusRow extends StatelessWidget {
  final _BlockData data;
  const _StatusRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: QeranColors.paper.withValues(alpha: 0.10),
            borderRadius: QeranRadii.controlR,
            border: Border.all(color: QeranColors.paper.withValues(alpha: 0.12)),
          ),
          child: Icon(data.icon, color: QeranColors.gold, size: 18),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: QeranTypography.bodySm.copyWith(color: QeranColors.paper),
          ),
        ),
        QeranSpacing.hs8,
        QeranChip(
          icon: data.chipIcon,
          label: data.status,
          variant: QeranChipVariant.status,
          statusColor: QeranColors.gold,
          compact: true,
        ),
      ],
    );
  }
}
