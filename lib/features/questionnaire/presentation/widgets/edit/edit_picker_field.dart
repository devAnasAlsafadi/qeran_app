import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/editable_question.dart';
import '../../../domain/entities/question_entity.dart';
import '../question_date_widget.dart';
import '../question_height_widget.dart';
import '../question_weight_widget.dart';
import 'edit_bottom_sheet.dart';
import 'edit_field_shell.dart';

/// Edit-form input for `date` / `height` / `weight`: a closed field showing
/// the current value. Tapping opens a brand bottom sheet hosting the shared
/// drum widget. The drum's value is buffered locally and committed only when
/// the user taps "تم" — so merely opening (and dismissing) a picker never
/// saves an untouched default the user didn't pick.
class EditPickerField extends StatelessWidget {
  final EditableQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const EditPickerField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EditFieldShell(
      value: _display(context),
      placeholder: LocaleKeys.profile_edit_select_hint.t(context),
      onTap: () => _open(context),
    );
  }

  String _display(BuildContext context) {
    switch (question.type) {
      case QuestionType.date:
        return value is DateTime ? _formatDate(value as DateTime) : '';
      case QuestionType.height:
        return value is int
            ? '$value ${LocaleKeys.questionnaire_height_unit.t(context)}'
            : '';
      case QuestionType.weight:
        return value is int
            ? '$value ${LocaleKeys.questionnaire_weight_unit.t(context)}'
            : '';
      default:
        return value?.toString() ?? '';
    }
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void _open(BuildContext context) {
    showEditSheet<void>(
      context,
      title: question.text,
      builder: (sheetContext) => _PickerSheetBody(
        type: question.type,
        initial: value,
        onConfirm: (picked) {
          onChanged(picked);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

/// Hosts the drum and a confirm button. The drum's live changes update only
/// a local buffer; nothing reaches the form until "تم" is tapped.
class _PickerSheetBody extends StatefulWidget {
  final QuestionType type;
  final dynamic initial;
  final ValueChanged<dynamic> onConfirm;

  const _PickerSheetBody({
    required this.type,
    required this.initial,
    required this.onConfirm,
  });

  @override
  State<_PickerSheetBody> createState() => _PickerSheetBodyState();
}

class _PickerSheetBodyState extends State<_PickerSheetBody> {
  late dynamic _buffer = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _drum(),
        const SizedBox(height: QeranSpacing.s16),
        QeranButton(
          label: LocaleKeys.profile_edit_done.t(context),
          onPressed: () => widget.onConfirm(_buffer),
          variant: QeranButtonVariant.primaryWine,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _drum() {
    switch (widget.type) {
      case QuestionType.date:
        return QuestionDateWidget(
          selectedDate: widget.initial is DateTime ? widget.initial as DateTime : null,
          onChanged: (d) => _buffer = d,
        );
      case QuestionType.weight:
        return QuestionWeightWidget(
          selectedWeight: widget.initial is int ? widget.initial as int : null,
          onChanged: (w) => _buffer = w,
        );
      case QuestionType.height:
      default:
        return QuestionHeightWidget(
          selectedHeight: widget.initial is int ? widget.initial as int : null,
          onChanged: (h) => _buffer = h,
        );
    }
  }
}
