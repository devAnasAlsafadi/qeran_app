import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Above the field after the filter refused a comment (D8): why, in danger
/// on its tint. The text stays in the field to be edited.
class ComposerRejectedBanner extends StatelessWidget {
  const ComposerRejectedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s12,
        QeranSpacing.s8,
        QeranSpacing.s12,
        0,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: QeranColors.danger08,
          borderRadius: QeranRadii.controlR,
        ),
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s12),
          child: _content(context),
        ),
      ),
    );
  }

  static Widget _content(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.block_rounded, size: 18, color: QeranColors.danger),
      QeranSpacing.hs8,
      Expanded(
        child: Text(
          LocaleKeys.community_filter_rejected.t(context),
          style: QeranTypography.bodySm.copyWith(color: QeranColors.danger),
        ),
      ),
    ],
  );
}

/// In place of the field for a member who can't take part yet (C10): why,
/// beside a lock.
class ComposerReadOnlyNotice extends StatelessWidget {
  const ComposerReadOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: QeranColors.goldDeep,
            ),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                LocaleKeys.community_read_only_comment.t(context),
                style: QeranTypography.bodySm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
