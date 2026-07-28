import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../users/presentation/widgets/matchmaker_notes_delete_confirm.dart';
import '../blocs/case_note/case_note_cubit.dart';
import '../blocs/case_note/case_note_state.dart';

/// The ready-state body of the case-note sheet: a multiline field (prefilled
/// from [initialContent]), an optional "last edited" caption (when a note
/// exists), an n/2000 counter (counted after `trim()`), and Save / Delete /
/// Cancel. Owns the text controller + the inline VALIDATION_ERROR message; the
/// parent sheet owns load states + success/terminal outcomes (toast + pop).
/// Save is disabled until the trimmed text is 1..2000 chars.
class CaseNoteEditor extends StatefulWidget {
  const CaseNoteEditor({super.key, this.initialContent, this.updatedAt});

  final String? initialContent;
  final DateTime? updatedAt;

  @override
  State<CaseNoteEditor> createState() => _CaseNoteEditorState();
}

class _CaseNoteEditorState extends State<CaseNoteEditor> {
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
      _trimmedLength > 0 && _trimmedLength <= CaseNoteCubit.maxLength;

  void _onChanged(String _) => setState(() {
        if (_inlineError != null) _inlineError = null;
      });

  Future<void> _onDelete(CaseNoteCubit cubit) async {
    final confirmed = await showDeleteNoteConfirm(context);
    if (confirmed == true) cubit.delete();
  }

  /// "Last edited {date}" — only when a note already exists with a timestamp.
  String? _lastEdited(BuildContext context) {
    final at = widget.updatedAt;
    if (at == null) return null;
    final date = DateFormat.yMMMMd(context.locale.toString()).format(at.toLocal());
    return LocaleKeys.matchmaker_case_note_last_edited
        .t(context)
        .replaceFirst('{date}', date);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaseNoteCubit>();
    final lastEdited = _lastEdited(context);
    return BlocListener<CaseNoteCubit, CaseNoteState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome == CaseNoteOutcome.failure &&
          c.errorKind == CaseNoteErrorKind.validation,
      listener: (context, _) => setState(
        () => _inlineError = LocaleKeys.matchmaker_notes_validation.t(context),
      ),
      child: BlocBuilder<CaseNoteCubit, CaseNoteState>(
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The title lives in the sheet scaffold's title row — repeating it
            // here would render it twice.
            Text(
              LocaleKeys.matchmaker_case_note_subtitle.t(context),
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
            if (lastEdited != null) ...[
              QeranSpacing.vs8,
              Text(
                lastEdited,
                style:
                    QeranTypography.caption.copyWith(color: QeranColors.inkFaint),
              ),
            ],
            QeranSpacing.vs16,
            QeranButton(
              label: LocaleKeys.matchmaker_notes_save.t(context),
              variant: QeranButtonVariant.primaryWine,
              loading: state.inFlight == CaseNoteAction.save,
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
                loading: state.inFlight == CaseNoteAction.delete,
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
    final over = length > CaseNoteCubit.maxLength;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        '$length/${CaseNoteCubit.maxLength}',
        style: QeranTypography.caption.copyWith(
          color: over ? QeranColors.danger : QeranColors.inkMuted,
        ),
      ),
    );
  }
}
