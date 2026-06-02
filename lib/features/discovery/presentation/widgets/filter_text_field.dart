import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

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
          padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.start,
            onChanged: (v) => widget.onChanged(v.trim()),
            style: QeranTypography.subtitle,
            decoration: InputDecoration(
              filled: true,
              fillColor: QeranColors.paper,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: QeranSpacing.s12,
                vertical: QeranSpacing.s12,
              ),
              border: const OutlineInputBorder(
                borderRadius: QeranRadii.controlR,
                borderSide: BorderSide(color: QeranColors.hairline),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: QeranRadii.controlR,
                borderSide: BorderSide(color: QeranColors.hairline),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: QeranRadii.controlR,
                borderSide: BorderSide(color: QeranColors.wine),
              ),
            ),
          ),
        );
      },
    );
  }
}
