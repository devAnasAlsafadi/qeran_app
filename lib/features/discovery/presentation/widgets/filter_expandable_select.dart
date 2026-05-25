import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

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
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
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
                          color: AppColors.primary,
                        ),
                      ),
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
