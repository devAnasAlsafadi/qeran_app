import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../domain/entities/discovery_filter_option.dart';
import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import 'filter_expandable_shell.dart';

/// Multi-choice expandable for `checkbox` questions. The cubit owns
/// add/remove semantics; this widget just emits the tapped value.
class FilterExpandableMulti extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final MultiValueSelection? selection;
  final ValueChanged<String> onToggle;

  const FilterExpandableMulti({
    super.key,
    required this.question,
    required this.selection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? const <DiscoveryFilterOption>[];
    final selected = selection?.values ?? const <String>[];
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
              _MultiRow(
                option: option,
                isSelected: selected.contains(option.value),
                onTap: () => onToggle(option.value),
              ),
          ],
        );
      },
    );
  }
}

class _MultiRow extends StatelessWidget {
  final DiscoveryFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiRow({
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
                borderRadius: QeranRadii.controlR,
                border: Border.all(
                  color: isSelected
                      ? QeranColors.wine
                      : QeranColors.hairline,
                  width: 2,
                ),
                color: isSelected
                    ? QeranColors.wine
                    : QeranColors.creamCanvas,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: QeranColors.paper,
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
