import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import 'filter_expandable_shell.dart';

/// Single-line text input for `text`-type filters (exact-match
/// `QuestionFilters[id]=value`).
///
/// Selection is cleared automatically when the field is empty, so
/// `buildPayload` never emits an empty filter value.
class FilterTextField extends StatefulWidget {
  final DiscoveryFilterQuestion question;
  final SingleValueSelection? selection;
  final ValueChanged<String> onChanged;

  const FilterTextField({
    super.key,
    required this.question,
    required this.selection,
    required this.onChanged,
  });

  @override
  State<FilterTextField> createState() => _FilterTextFieldState();
}

class _FilterTextFieldState extends State<FilterTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selection?.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilterExpandableShell(
      label: widget.question.label,
      bodyBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.end,
            onChanged: (v) => widget.onChanged(v.trim()),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p12,
                vertical: AppDimens.p12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        );
      },
    );
  }
}
