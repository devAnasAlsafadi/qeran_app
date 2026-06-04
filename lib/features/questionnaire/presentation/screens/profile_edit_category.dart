import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';

import '../../domain/entities/editable_category.dart';
import '../../domain/entities/editable_question.dart';
import '../../domain/entities/question_entity.dart';
import 'profile_edit_question_field.dart';

/// One category page in the edit form. Field-type questions sit inside a
/// white card (Figma); a height + weight pair is laid out side by side on one
/// row. A category that is entirely chip-type (e.g. الصفات) renders its chip
/// grids directly on the canvas, cardless, to match Figma.
class ProfileEditCategory extends StatelessWidget {
  final EditableCategory category;

  const ProfileEditCategory({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s20,
        QeranSpacing.s20,
        QeranSpacing.s24,
      ),
      child: _isAllChips ? content : QeranCard(child: content),
    );
  }

  bool get _isAllChips =>
      category.questions.isNotEmpty &&
      category.questions.every((q) =>
          q.type == QuestionType.checkbox || q.type == QuestionType.interests);

  /// Builds the field rows, pairing an adjacent height + weight onto one row.
  List<Widget> _buildRows() {
    final questions = category.questions;
    final rows = <Widget>[];
    var i = 0;
    while (i < questions.length) {
      final current = questions[i];
      final next = i + 1 < questions.length ? questions[i + 1] : null;
      if (next != null && _isHeightWeightPair(current, next)) {
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ProfileEditQuestionField(question: current)),
            const SizedBox(width: QeranSpacing.s12),
            Expanded(child: ProfileEditQuestionField(question: next)),
          ],
        ));
        i += 2;
      } else {
        rows.add(ProfileEditQuestionField(question: current));
        i += 1;
      }
    }
    return rows;
  }

  bool _isHeightWeightPair(EditableQuestion a, EditableQuestion b) {
    final types = {a.type, b.type};
    return types.contains(QuestionType.height) &&
        types.contains(QuestionType.weight);
  }
}
