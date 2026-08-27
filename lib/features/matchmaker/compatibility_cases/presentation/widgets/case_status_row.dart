import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';

/// One labelled row of the case-detail status card, and the hairline between
/// two of them. Lifted out of [CaseStatusSection] whole — the section decides
/// WHICH rows exist and what they say, and this decides how a row shares its
/// width. They are separate questions and the second one has the arithmetic.

class CaseStatusRow extends StatelessWidget {
  const CaseStatusRow({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String labelKey;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: QeranColors.wine06,
            borderRadius: QeranRadii.xsR,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: QeranColors.wine),
        ),
        QeranSpacing.hs12,
        // The label is NOT flexible, and that is the fix rather than an
        // oversight. It used to be Expanded beside a Flexible value: two flex-1
        // children split the row 50/50, and a loose child's leftovers are not
        // handed back to its sibling — so «المرحلة», which needs 38.6dp, held a
        // 112dp column while the value wrapped in the other half.
        // «التواصل الرسمي مع الأهل» is 165.4dp. Sized to its text,
        // the label leaves 185.4dp at 360 and 145.4dp at 320, and the wrap goes.
        //
        // Safe because these are four fixed field labels, the widest 104.2dp
        // against 184dp available even at 320dp — pinned in
        // case_status_section_test.dart rather than left to luck.
        Text(labelKey.t(context), style: QeranTypography.caption),
        QeranSpacing.hs12,
        Expanded(
          child: Text(
            value,
            style: QeranTypography.label.copyWith(color: valueColor),
            textAlign: TextAlign.end,
            // Deliberately unbounded. The two longest values a row can hold
            // (239.2dp AR, 243.0dp EN) outrun the whole 224dp row, so they wrap
            // whatever we do; truncating a case's status is worse than a second
            // line.
          ),
        ),
      ],
    );
  }
}

class CaseStatusRowDivider extends StatelessWidget {
  const CaseStatusRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Divider(height: 1, color: QeranColors.divider),
    );
  }
}
