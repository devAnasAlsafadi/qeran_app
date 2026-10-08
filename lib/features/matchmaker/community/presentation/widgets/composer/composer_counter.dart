import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';

/// The text's counter, over the toolbar (C1, C7): «n / limit» at the end —
/// always there once the limit is read (S2) — danger past the limit, with
/// «النص أطول من الحد المسموح.» at the start. Nothing while the limit isn't
/// known: the server checks the length then (S19).
class ComposerCounter extends StatelessWidget {
  const ComposerCounter({super.key, required this.draft});

  final PostDraftState draft;

  static const _padding = EdgeInsets.fromLTRB(
    QeranSpacing.s20,
    QeranSpacing.s6,
    QeranSpacing.s20,
    QeranSpacing.s12,
  );

  @override
  Widget build(BuildContext context) {
    final limit = draft.maxLength;
    if (limit == null) return const SizedBox.shrink();
    final over = draft.tooLong;
    return Padding(
      padding: _padding,
      child: Row(
        children: [
          Expanded(child: over ? _tooLong(context) : const SizedBox.shrink()),
          const SizedBox(width: QeranSpacing.s8),
          Text(
            '${draft.length} / $limit',
            textDirection: TextDirection.ltr,
            style: QeranTypography.numeric.copyWith(
              fontSize: QeranTypography.caption.fontSize,
              color: over ? QeranColors.danger : QeranColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tooLong(BuildContext context) => Text(
    LocaleKeys.matchmaker_community_text_too_long.t(context),
    style: QeranTypography.caption.copyWith(
      color: QeranColors.danger,
      fontWeight: FontWeight.w700,
    ),
  );
}
