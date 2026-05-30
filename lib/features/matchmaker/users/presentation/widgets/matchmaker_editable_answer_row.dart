import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/app_text_form_field.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_editable_answer.dart';
import '../blocs/matchmaker_answer_save_cubit.dart';

/// One editable answer: shows the question + current answer with an Edit
/// affordance; tapping Edit reveals an inline multiline field with
/// Save / Cancel. The Save button disables while empty or unchanged, shows
/// a loader while in flight, and the row leaves edit mode automatically
/// once the answer is updated in place (after a successful save).
class MatchmakerEditableAnswerRow extends StatefulWidget {
  const MatchmakerEditableAnswerRow({super.key, required this.answer});

  final MatchmakerEditableAnswer answer;

  @override
  State<MatchmakerEditableAnswerRow> createState() =>
      _MatchmakerEditableAnswerRowState();
}

class _MatchmakerEditableAnswerRowState
    extends State<MatchmakerEditableAnswerRow> {
  final TextEditingController _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MatchmakerEditableAnswerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A successful save updates currentAnswer from outside → leave edit mode.
    if (_editing &&
        oldWidget.answer.currentAnswer != widget.answer.currentAnswer) {
      setState(() => _editing = false);
    }
  }

  void _startEdit() {
    _controller.text = widget.answer.currentAnswer;
    setState(() => _editing = true);
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context
        .read<MatchmakerAnswerSaveCubit>()
        .save(questionId: widget.answer.questionId, textAnswer: text);
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<MatchmakerAnswerSaveCubit, bool>(
      (c) => c.state.isSaving(widget.answer.questionId),
    );
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.answer.question, style: QeranTypography.subtitle),
          QeranSpacing.vs8,
          if (_editing) _editView(context, saving) else _readView(context),
        ],
      ),
    );
  }

  Widget _readView(BuildContext context) {
    final empty = widget.answer.currentAnswer.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          empty
              ? LocaleKeys.matchmaker_answers_empty_value.t(context)
              : widget.answer.currentAnswer,
          style: QeranTypography.body.copyWith(
            color: empty ? QeranColors.inkMuted : null,
          ),
        ),
        QeranSpacing.vs8,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: QeranButton(
            label: LocaleKeys.matchmaker_answers_edit.t(context),
            variant: QeranButtonVariant.ghost,
            size: QeranButtonSize.sm,
            fullWidth: false,
            leadingIcon: Icons.edit_outlined,
            onPressed: _startEdit,
          ),
        ),
      ],
    );
  }

  Widget _editView(BuildContext context, bool saving) {
    final text = _controller.text.trim();
    final canSave = text.isNotEmpty && text != widget.answer.currentAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextFormField(
          controller: _controller,
          hintText: LocaleKeys.matchmaker_answers_hint.t(context),
          obscureText: false,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 4,
          fillColor: QeranColors.creamSurface,
          onChange: (_) => setState(() {}),
        ),
        QeranSpacing.vs12,
        Row(
          children: [
            Expanded(
              child: QeranButton(
                label: LocaleKeys.matchmaker_profile_action_cancel.t(context),
                variant: QeranButtonVariant.ghost,
                size: QeranButtonSize.md,
                onPressed: saving ? null : () => setState(() => _editing = false),
              ),
            ),
            QeranSpacing.hs12,
            Expanded(
              child: QeranButton(
                label: LocaleKeys.matchmaker_answers_save.t(context),
                variant: QeranButtonVariant.primary,
                size: QeranButtonSize.md,
                loading: saving,
                onPressed: (saving || !canSave) ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
