import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/editable_question.dart';
import '../question_select_widget.dart';
import 'edit_bottom_sheet.dart';
import 'edit_field_shell.dart';

/// Edit-form input for `select` / `radio`: a closed dropdown row showing the
/// current choice. Tapping opens a brand bottom sheet hosting the shared
/// [QuestionSelectWidget] (the same single-select list used at sign-up), so
/// picking an option flows straight back through [onChanged].
class EditDropdownField extends StatelessWidget {
  final EditableQuestion question;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const EditDropdownField({
    super.key,
    required this.question,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EditFieldShell(
      value: _selectedText(),
      placeholder: LocaleKeys.profile_edit_select_hint.t(context),
      onTap: () => _open(context),
    );
  }

  String _selectedText() {
    for (final option in question.options) {
      if (option.id == selectedId) return option.text;
    }
    return '';
  }

  void _open(BuildContext context) {
    showEditSheet<void>(
      context,
      title: question.text,
      builder: (sheetContext) => SingleChildScrollView(
        child: QuestionSelectWidget(
          question: question.toQuestionEntity(),
          selectedOptionId: selectedId,
          onChanged: (id) {
            onChanged(id);
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }
}
