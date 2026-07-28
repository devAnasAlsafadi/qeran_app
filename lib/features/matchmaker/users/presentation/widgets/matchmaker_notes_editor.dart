import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_user_notes_cubit.dart';
import '../blocs/matchmaker_user_notes_state.dart';
import 'matchmaker_notes_delete_confirm.dart';

/// The ready-state body of the notes sheet: a multiline field (prefilled from
/// [initialContent]), an n/2000 counter (counted after `trim()`), and Save /
/// Delete / Cancel. Owns the text controller + the inline VALIDATION_ERROR
/// message; the parent sheet owns load states + success/terminal outcomes
/// (toast + pop). Save is disabled until the trimmed text is 1..2000 chars.
class MatchmakerNotesEditor extends StatefulWidget {
  const MatchmakerNotesEditor({super.key, this.initialContent});

  final String? initialContent;

  @override
  State<MatchmakerNotesEditor> createState() => _MatchmakerNotesEditorState();
}

class _MatchmakerNotesEditorState extends State<MatchmakerNotesEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialContent ?? '');
  String? _inlineError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _trimmedLength => _controller.text.trim().length;
  bool get _canSave =>
      _trimmedLength > 0 && _trimmedLength <= MatchmakerUserNotesCubit.maxLength;

  void _onChanged(String _) => setState(() {
        if (_inlineError != null) _inlineError = null;
      });

  Future<void> _onDelete(MatchmakerUserNotesCubit cubit) async {
    final confirmed = await showDeleteNoteConfirm(context);
    if (confirmed == true) cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerUserNotesCubit>();
    return BlocListener<MatchmakerUserNotesCubit, MatchmakerUserNotesState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome == MatchmakerNotesOutcome.failure &&
          c.errorKind == MatchmakerNotesErrorKind.validation,
      listener: (context, _) => setState(
        () => _inlineError = LocaleKeys.matchmaker_notes_validation.t(context),
      ),
      child: BlocBuilder<MatchmakerUserNotesCubit, MatchmakerUserNotesState>(
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The title lives in the sheet scaffold's title row — repeating it
            // here would render it twice.
            Text(
              LocaleKeys.matchmaker_notes_subtitle.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs16,
            QeranTextField(
              controller: _controller,
              hint: LocaleKeys.matchmaker_notes_hint.t(context),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 6,
              errorText: _inlineError,
              onChanged: _onChanged,
            ),
            QeranSpacing.vs8,
            _Counter(length: _trimmedLength),
            QeranSpacing.vs16,
            QeranButton(
              label: LocaleKeys.matchmaker_notes_save.t(context),
              variant: QeranButtonVariant.primaryWine,
              loading: state.inFlight == MatchmakerNotesAction.save,
              onPressed: (!_canSave || state.isBusy)
                  ? null
                  : () => cubit.save(_controller.text),
            ),
            if (state.hasNote) ...[
              QeranSpacing.vs8,
              QeranButton(
                label: LocaleKeys.matchmaker_notes_delete.t(context),
                variant: QeranButtonVariant.destructive,
                size: QeranButtonSize.md,
                loading: state.inFlight == MatchmakerNotesAction.delete,
                onPressed: state.isBusy ? null : () => _onDelete(cubit),
              ),
            ],
            QeranSpacing.vs8,
            QeranButton(
              label: LocaleKeys.matchmaker_profile_action_cancel.t(context),
              variant: QeranButtonVariant.ghost,
              size: QeranButtonSize.md,
              onPressed: state.isBusy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing "n/2000" counter — danger-tinted when the trimmed length exceeds
/// the limit (Save is already disabled in that case).
class _Counter extends StatelessWidget {
  const _Counter({required this.length});

  final int length;

  @override
  Widget build(BuildContext context) {
    final over = length > MatchmakerUserNotesCubit.maxLength;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        '$length/${MatchmakerUserNotesCubit.maxLength}',
        style: QeranTypography.caption.copyWith(
          color: over ? QeranColors.danger : QeranColors.inkMuted,
        ),
      ),
    );
  }
}
