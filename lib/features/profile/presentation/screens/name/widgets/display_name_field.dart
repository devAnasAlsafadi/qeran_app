import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_helper_line.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The display-name input, on Profile › Name and on Community's name step
/// (F1–F4): the server's limits, a help line saying where the name shows —
/// and, as soon as it's typed, why the placeholder won't do (F2). After the
/// filter refused a name ([filteredName], Q10) it says so while that name
/// is still in the field.
class DisplayNameField extends StatelessWidget {
  const DisplayNameField({
    super.key,
    required this.controller,
    this.filteredName,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? filteredName;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => QeranTextField(
        controller: controller,
        label: LocaleKeys.profile_name_display_label.t(context),
        hint: LocaleKeys.profile_name_input_hint.t(context),
        enabled: enabled,
        maxLength: Validators.displayNameMax,
        textInputAction: textInputAction,
        validator: Validators.validateDisplayName,
        errorText: _liveError(context, value.text.trim()),
        helper: QeranHelperLine(
          icon: Icons.forum_outlined,
          text: LocaleKeys.profile_name_display_help.t(context),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }

  /// What's wrong with [name] while it's typed: still the placeholder, or
  /// the name the filter refused. Everything else waits for a save.
  String? _liveError(BuildContext context, String name) {
    if (Validators.isDefaultDisplayName(name)) {
      return LocaleKeys.profile_name_default_error.t(context);
    }
    if (name.isNotEmpty && name == filteredName) {
      return LocaleKeys.profile_name_filtered_error.t(context);
    }
    return null;
  }
}
