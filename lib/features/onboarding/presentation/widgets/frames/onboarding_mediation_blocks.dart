import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The mediation flow: three status cards — inquiry sent → response received →
/// families' details — separated by a soft down-chevron to read as a sequence.
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
          if (i > 0)
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: QeranColors.gold40,
              size: 22,
            ),
          _StatusBlock(data: blocks[i]),
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

class _StatusBlock extends StatelessWidget {
  final _BlockData data;
  const _StatusBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper.withValues(alpha: 0.06),
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.paper.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: QeranColors.gold12,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: QeranColors.gold, size: 18),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: QeranTypography.subtitle.copyWith(color: QeranColors.paper),
            ),
          ),
          QeranSpacing.hs8,
          QeranChip(
            icon: data.chipIcon,
            label: data.status,
            variant: QeranChipVariant.meta,
            compact: true,
          ),
        ],
      ),
    );
  }
}
