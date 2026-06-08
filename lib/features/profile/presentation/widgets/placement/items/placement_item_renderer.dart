import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';

import '../../../../domain/entities/placement_item.dart';
import '../../../../domain/entities/placement_item_type.dart';
import '../../../../domain/entities/placement_value.dart';
import '../text_answer_edit_scope.dart';
import 'inline_chip.dart';

/// Answers shorter than this render inline (question on the start edge,
/// answer on the end edge). Longer answers wrap onto their own line below
/// the question — matching Figma's "الديانة … مسلمة سنّية" layout.
const int _kInlineMaxChars = 24;

/// Item-level dispatcher. Single answers render as a question/answer row
/// (label muted on the start edge, answer emphasized on the end edge);
/// multi answers render as a label with a wrap of chips beneath.
///
/// When a [TextAnswerEditScope] is installed by an ancestor (matchmaker only),
/// each `type == text` item gains a trailing edit pencil. With no scope (the
/// default everywhere else) the row renders EXACTLY as before — purely
/// additive, behind a null-guard.
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

    final scope = TextAnswerEditScope.maybeOf(context);
    if (scope == null || item.type != PlacementItemType.text) {
      return content; // unchanged — user app / my-profile / non-text items
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        const SizedBox(width: QeranSpacing.s8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
          child: _EditAffordance(
            loading: scope.inFlightQuestionId == item.questionId,
            onTap: () => scope.onEdit(item),
          ),
        ),
      ],
    );
  }
}

/// Small softFill edit pencil for an editable text answer (matchmaker DS
/// style). Shows an inline loader in place of the pencil while its save is in
/// flight, with taps suppressed.
class _EditAffordance extends StatelessWidget {
  const _EditAffordance({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.softFill,
      borderRadius: QeranRadii.pill,
      child: InkWell(
        borderRadius: QeranRadii.pill,
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s6),
          child: SizedBox(
            width: 16,
            height: 16,
            child: loading
                ? const FittedBox(child: QeranLoader.inline(color: QeranColors.wine))
                : const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: QeranColors.wine,
                  ),
          ),
        ),
      ),
    );
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
