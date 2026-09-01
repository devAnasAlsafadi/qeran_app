import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../tokens/qeran_colors.dart';
import 'qeran_text_field.dart';

/// The one search affordance for filtering an on-screen list of options.
///
/// A [QeranTextField] with the magnifier in the leading slot — passed as
/// `prefix`, so it mirrors to the trailing edge under RTL with no manual swap,
/// the same way the field's own directional padding does.
///
/// Extracted from the searchable filter facet so the questionnaire's long
/// single-select lists (nationality, country of residence) search through the
/// same control rather than a lookalike. It renders exactly what the facet
/// rendered before the extraction: any change here moves the discovery filters
/// and the matchmaker's explore filters with it.
///
/// Deliberately has NO clear button — adding one is a change to every surface
/// that uses this field, to be made on purpose rather than inherited.
class QeranSearchField extends StatelessWidget {
  const QeranSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  /// Overrides the default "search the options" placeholder. Callers whose
  /// list is not a generic option set pass their own.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return QeranTextField(
      controller: controller,
      focusNode: focusNode,
      hint: hint ?? LocaleKeys.filters_search_hint.t(context),
      prefix: const Icon(
        Icons.search_rounded,
        color: QeranColors.inkFaint,
        size: 20,
      ),
      onChanged: onChanged,
    );
  }
}
