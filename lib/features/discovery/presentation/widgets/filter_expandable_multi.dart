import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

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
            padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
            child: Text(
              question.label,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
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
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.primary
                    : AppColors.background,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.white,
                    )
                  : null,
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Text(
                option.display,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
