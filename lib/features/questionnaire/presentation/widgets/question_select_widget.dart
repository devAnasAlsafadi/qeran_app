import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import '../../domain/entities/question_entity.dart';

/// Renders a single-select list of radio options (matching Figma reference).
class QuestionSelectWidget extends StatelessWidget {
  final QuestionEntity question;
  final String? selectedOptionId;
  final ValueChanged<String> onChanged;

  const QuestionSelectWidget({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: question.options
          .map(
            (option) => _OptionRow(
              label: option.text,
              isSelected: selectedOptionId == option.id,
              onTap: () => onChanged(option.id),
            ),
          )
          .toList(),
    );
  }
}

/// One tappable row: the radio circle and its label.
///
/// The circle is drawn rather than taken from Material so it carries the
/// wine/hairline pair from the design system; the row leaves its own left/right
/// placement to the ambient direction, so AR mirrors it without a manual swap.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
        child: Row(
          children: [
            _RadioCircle(isSelected: isSelected),
            QeranSpacing.hs16,
            Expanded(
              child: Text(
                label,
                style: isSelected
                    ? QeranTypography.subtitle
                    : QeranTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The selection indicator: a wine ring that fills with a wine dot when chosen.
class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? QeranColors.wine : QeranColors.hairline,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QeranColors.wine,
                ),
              ),
            )
          : null,
    );
  }
}
