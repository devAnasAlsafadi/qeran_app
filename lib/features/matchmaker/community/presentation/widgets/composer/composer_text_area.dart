import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/utils/own_text_direction.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';

/// Where she writes (C1, C2, C7): the text in its own direction as she types
/// (D13), then the counter — always there, «n / limit» (S2) — which turns
/// danger past the limit with «النص أطول من الحد المسموح.».
class ComposerTextArea extends StatelessWidget {
  const ComposerTextArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.draft,
    required this.locked,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PostDraftState draft;

  /// Publishing: the draft can't change (S3).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: locked,
            autofocus: true,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textDirection: ownTextDirection(text),
            style: QeranTypography.body.copyWith(
              color: QeranColors.inkStrong,
              fontFamily: QeranOwnText.fontFamilyFor(text),
            ),
            cursorColor: QeranColors.goldDeep,
            decoration: InputDecoration.collapsed(
              hintText: LocaleKeys.matchmaker_community_composer_hint.t(
                context,
              ),
              hintStyle: QeranTypography.body.copyWith(
                color: QeranColors.inkFaint,
              ),
            ),
          ),
        ),
        _CounterLine(draft: draft),
      ],
    );
  }
}

/// «النص أطول…» at the start when it's too long; «n / limit» at the end.
class _CounterLine extends StatelessWidget {
  const _CounterLine({required this.draft});

  final PostDraftState draft;

  @override
  Widget build(BuildContext context) {
    final limit = draft.maxLength;
    final over = draft.tooLong;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s6,
        QeranSpacing.s20,
        QeranSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: over
                ? Text(
                    LocaleKeys.matchmaker_community_text_too_long.t(context),
                    style: QeranTypography.caption.copyWith(
                      color: QeranColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: QeranSpacing.s8),
          if (limit != null)
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
}
