import 'package:flutter/material.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_composer.dart';
import '../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/own_text_direction.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/community_composer_state.dart';

/// The field and the send button (D1, D3, D4): the field writes in the
/// typed text's own direction and script (Q8); from 80 % of the server's
/// limit a counter shows under it (S3), and past the limit the edge and the
/// counter turn danger and sending stops. Sending also rests after a rate
/// limit (D9). While a step is owed the field waits: a tap opens the step
/// ([onWaitingTap]), and nothing is sent.
class ComposerFieldRow extends StatelessWidget {
  const ComposerFieldRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onSend,
    required this.onWaitingTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final CommunityComposerState state;
  final VoidCallback onSend;
  final VoidCallback onWaitingTap;

  /// The counter's line, which the send button rises above.
  static const double _counterHeight = 18;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final over = state.tooLong(text);
    final from = state.counterFrom;
    final counted = from != null && text.trim().length >= from;
    final canSend = _canSend(text, over: over);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _field(context, error: over || state.filtered),
                if (counted) _Counter(length: text.trim().length, state: state),
              ],
            ),
          ),
          QeranSpacing.hs8,
          _send(counted: counted, enabled: canSend),
        ],
      ),
    );
  }

  /// Text to send, within the limit, not resting (D9) and no step owed.
  bool _canSend(String text, {required bool over}) =>
      text.trim().isNotEmpty &&
      !over &&
      !state.coolingDown &&
      state.owes == null;

  /// In line with the field, above the counter when it shows.
  Widget _send({required bool counted, required bool enabled}) => Padding(
    padding: EdgeInsets.only(bottom: counted ? _counterHeight : 0),
    child: QeranSendButton(enabled: enabled, onPressed: onSend),
  );

  Widget _field(BuildContext context, {required bool error}) {
    final text = controller.text;
    final hint = state.replyTo == null
        ? LocaleKeys.community_composer_comment.forReader(
            her: LocaleKeys.community_her_composer_comment,
          )
        : LocaleKeys.community_composer_reply.forReader(
            her: LocaleKeys.community_her_composer_reply,
          );
    return QeranComposerField(
      controller: controller,
      focusNode: focusNode,
      hint: hint.t(context),
      error: error,
      textDirection: ownTextDirection(text),
      fontFamily: QeranOwnText.fontFamilyFor(text),
      readOnly: state.owes != null,
      onTap: state.owes == null ? null : onWaitingTap,
    );
  }
}

/// «482 / 500», left to right in the numeric face.
class _Counter extends StatelessWidget {
  const _Counter({required this.length, required this.state});

  final int length;
  final CommunityComposerState state;

  @override
  Widget build(BuildContext context) {
    final over = length > (state.maxLength ?? length);
    return SizedBox(
      height: ComposerFieldRow._counterHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            '$length / ${state.maxLength}',
            textDirection: TextDirection.ltr,
            style: QeranTypography.numeric.copyWith(
              fontSize: QeranTypography.caption.fontSize,
              color: over ? QeranColors.danger : QeranColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
