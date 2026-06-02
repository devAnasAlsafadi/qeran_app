import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../domain/entities/discovery_filter_option.dart';
import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import 'filter_expandable_shell.dart';

/// Single-choice expandable for `select` / `radio` questions (and the
/// unknown-with-options fallback). Tapping the active row clears the
/// selection — the cubit handles the toggle.
class FilterExpandableSelect extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final SingleValueSelection? selection;
  final ValueChanged<String> onChanged;

  const FilterExpandableSelect({
    super.key,
    required this.question,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? const <DiscoveryFilterOption>[];
    return FilterExpandableShell(
      label: question.label,
      bodyBuilder: (context) {
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
            child: Text(
              question.label,
              textAlign: TextAlign.start,
              style: QeranTypography.body.copyWith(
                color: QeranColors.inkMuted,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final option in options)
              _SelectRow(
                option: option,
                isSelected: selection?.value == option.value,
                onTap: () => onChanged(option.value),
              ),
          ],
        );
      },
    );
  }
}

class _SelectRow extends StatelessWidget {
  final DiscoveryFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? QeranColors.wine
                      : QeranColors.hairline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: QeranColors.wine,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: QeranSpacing.s12),
            Expanded(
              child: Text(
                option.display,
                textAlign: TextAlign.start,
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
