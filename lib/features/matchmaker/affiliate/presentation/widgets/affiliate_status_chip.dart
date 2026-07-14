import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/affiliate_commission_status.dart';

/// Settlement-state pill for a commission row. Feature-local (the shared
/// `QeranChip` gets NO new variant); it maps each status to a DS token trio:
///   • confirmed → plan trio  (gold-12 fill / gold-deep text / gold-40 border)
///   • pending   → gold-pending fill / gold-deep text / gold-40 border
///   • reversed  → transparent fill / ink-muted text / wine-12 border
/// Consumes tokens only — never raw hex.
class AffiliateStatusChip extends StatelessWidget {
  const AffiliateStatusChip({super.key, required this.status});

  final AffiliateCommissionStatus status;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s8,
        vertical: QeranSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: QeranRadii.pill,
        border: Border.all(color: spec.border),
      ),
      child: Text(
        spec.label.t(context),
        style: QeranTypography.caption.copyWith(
          color: spec.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusSpec _specFor(AffiliateCommissionStatus status) => switch (status) {
        AffiliateCommissionStatus.confirmed => const _StatusSpec(
            bg: QeranColors.gold12,
            fg: QeranColors.goldDeep,
            border: QeranColors.gold40,
            label: LocaleKeys.matchmaker_affiliate_status_confirmed,
          ),
        AffiliateCommissionStatus.pending => const _StatusSpec(
            bg: QeranColors.goldPending,
            fg: QeranColors.goldDeep,
            border: QeranColors.gold40,
            label: LocaleKeys.matchmaker_affiliate_status_pending,
          ),
        AffiliateCommissionStatus.reversed => const _StatusSpec(
            bg: Colors.transparent,
            fg: QeranColors.inkMuted,
            border: QeranColors.wine12,
            label: LocaleKeys.matchmaker_affiliate_status_reversed,
          ),
      };
}

class _StatusSpec {
  const _StatusSpec({
    required this.bg,
    required this.fg,
    required this.border,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final Color border;
  final String label;
}
