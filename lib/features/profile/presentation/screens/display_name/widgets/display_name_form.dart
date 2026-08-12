import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'display_name_notice.dart';

/// The editable half of the name screen: the cooldown warning (when one
/// applies), the input, and Save.
class DisplayNameForm extends StatefulWidget {
  const DisplayNameForm({
    super.key,
    required this.currentName,
    required this.isDefaultName,
    required this.saving,
    required this.onSave,
  });

  final String currentName;

  /// The current name is the server-assigned placeholder. It is not worth
  /// editing, so the field starts empty — and no cooldown warning is shown,
  /// because the first real edit is the one that starts the clock.
  final bool isDefaultName;
  final bool saving;
  final ValueChanged<String> onSave;

  @override
  State<DisplayNameForm> createState() => _DisplayNameFormState();
}

class _DisplayNameFormState extends State<DisplayNameForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isDefaultName ? '' : widget.currentName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Saving is pointless unless the name actually changed — a no-op write
  /// would burn the member's 7-day cooldown for nothing.
  bool get _isDirty {
    final value = _controller.text.trim();
    return value.isNotEmpty && value != widget.currentName;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isDefaultName) ...[
          DisplayNameNotice(
            icon: Icons.info_outline_rounded,
            message: LocaleKeys.profile_name_cooldown_warning.t(context),
          ),
          QeranSpacing.vs16,
        ],
        Form(
          key: _formKey,
          child: QeranTextField(
            controller: _controller,
            label: LocaleKeys.profile_name_input_label.t(context),
            hint: LocaleKeys.profile_name_input_hint.t(context),
            enabled: !widget.saving,
            maxLength: Validators.displayNameMax,
            textInputAction: TextInputAction.done,
            validator: Validators.validateDisplayName,
            // Rebuild so Save tracks whether the name has actually changed.
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ),
        QeranSpacing.vs16,
        QeranButton(
          label: LocaleKeys.settings_save_changes.t(context),
          variant: QeranButtonVariant.primaryWine,
          loading: widget.saving,
          onPressed: (widget.saving || !_isDirty) ? null : _submit,
        ),
      ],
    );
  }
}
