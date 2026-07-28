import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../../../domain/entities/placement_item.dart';
import '../../../../domain/entities/placement_value.dart';
import 'editable_text_answer.dart';
import 'inline_chip.dart';

/// Answers shorter than this render inline (question on the start edge,
/// answer on the end edge). Longer answers wrap onto their own line below
/// the question — matching Figma's "الديانة … مسلمة سنّية" layout.
const int _kInlineMaxChars = 24;

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
        PlacementSingle(value: final s) =>
          _SingleRow(question: item.question, answer: s),
        PlacementMulti(values: final vs) =>
          _MultiRow(question: item.question, values: vs),
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

  @override
  Widget build(BuildContext context) {
    final inline = answer.trim().length <= _kInlineMaxChars;
    if (inline) {
      // Question + answer sit beside each other at comparable sizes —
      // the answer is only slightly emphasized (dark vs muted), never
      // larger. Grouped close together, not pushed to opposite edges.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              question,
              textAlign: TextAlign.start,
              style: _questionStyle,
            ),
          ),
          const SizedBox(width: QeranSpacing.s8),
          Flexible(
            child: Text(
              answer,
              textAlign: TextAlign.start,
              style: _answerStyle,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, textAlign: TextAlign.start, style: _questionStyle),
        const SizedBox(height: QeranSpacing.s6),
        Text(answer, textAlign: TextAlign.start, style: _answerStyle),
      ],
    );
  }

  static final TextStyle _questionStyle =
      QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted);

  static final TextStyle _answerStyle = QeranTypography.bodySm.copyWith(
    color: QeranColors.inkStrong,
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
        Text(question, textAlign: TextAlign.start, style: QeranTypography.caption),
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
