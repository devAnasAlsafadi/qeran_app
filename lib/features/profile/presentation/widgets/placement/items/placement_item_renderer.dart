import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../../../domain/entities/placement_item.dart';
import '../../../../domain/entities/placement_value.dart';
import 'editable_text_answer.dart';
import 'inline_chip.dart';

/// Item-level dispatcher. Single answers render as a question/answer row
/// (label muted on the start edge, answer emphasized on the end edge);
/// multi answers render as a label with a wrap of chips beneath.
///
/// The trailing edit pencil for `type == text` items comes from the shared
/// [EditableTextAnswer] wrapper — see it for the null-guard that keeps the user
/// app, my-profile and non-text items rendering exactly as before.
class PlacementItemRenderer extends StatelessWidget {
  final PlacementItem item;
  const PlacementItemRenderer({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
      child: switch (item.display) {
        PlacementSingle(value: final s) => _SingleRow(
          question: item.question,
          answer: s,
        ),
        PlacementMulti(values: final vs) => _MultiRow(
          question: item.question,
          values: vs,
        ),
      },
    );

    // The pencil (and its null-guard) lives in the shared wrapper, which the
    // narrative نبذات use too. Output here is unchanged: the wrapper builds the
    // same Row with the same `vertical: s8` affordance padding this used.
    return EditableTextAnswer(item: item, child: content);
  }
}

class _SingleRow extends StatelessWidget {
  final String question;
  final String answer;
  const _SingleRow({required this.question, required this.answer});

  /// The question takes the width it needs and wraps only when a whole line
  /// can't hold it; the answer follows on the same line when it fits, and
  /// starts the next line when it doesn't (run 7, Anas's rule for the profile
  /// view). A [Row] used to split the width between the two, so a question
  /// wrapped beside its answer with room left on the line.
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s6,
      children: [
        Text(question, textAlign: TextAlign.start, style: questionStyle),
        Text(answer, textAlign: TextAlign.start, style: _answerStyle),
      ],
    );
  }

  /// The body text's own colour: questions are plain text; only the answers
  /// take the identity's wine.
  static const TextStyle questionStyle = QeranTypography.body;

  static final TextStyle _answerStyle = QeranTypography.body.copyWith(
    color: QeranColors.wine,
    fontWeight: FontWeight.w600,
  );
}

class _MultiRow extends StatelessWidget {
  final String question;
  final List<String> values;
  const _MultiRow({required this.question, required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          textAlign: TextAlign.start,
          style: _SingleRow.questionStyle,
        ),
        const SizedBox(height: QeranSpacing.s6),
        Wrap(
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s6,
          children: values
              .where((v) => v.trim().isNotEmpty)
              .map(InlineChip.new)
              .toList(growable: false),
        ),
      ],
    );
  }
}
