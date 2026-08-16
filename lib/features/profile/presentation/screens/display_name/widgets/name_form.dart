import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Both names in one form, saved by one action. Neither field is locked — the
/// backend has no cooldown, so the only gates are "is it valid" and "did it
/// actually change".
class NameForm extends StatefulWidget {
  const NameForm({
    super.key,
    required this.currentDisplayName,
    required this.currentRealName,
    required this.isDefaultName,
    required this.saving,
    required this.onSave,
  });

  /// The saved display name — the baseline the field is diffed against.
  final String currentDisplayName;

  /// The saved real name, or null when the member has none on file.
  final String? currentRealName;

  /// The display name is still the server-assigned placeholder. It is not
  /// worth editing, so that field starts empty rather than pre-filled with
  /// a value the member never chose.
  final bool isDefaultName;
  final bool saving;

  /// Fires with the raw field text. Deciding what "unchanged", "cleared" and
  /// "set" mean for [realName] is the cubit's job, not the form's.
  final void Function({required String displayName, String? realName}) onSave;

  @override
  State<NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<NameForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _realName;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
      text: widget.isDefaultName ? '' : widget.currentDisplayName,
    );
    _realName = TextEditingController(text: widget.currentRealName ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _realName.dispose();
    super.dispose();
  }

  /// Whether either field differs from what the server holds. Saving an
  /// unchanged pair would be a write with nothing to write.
  bool get _isDirty {
    final display = _displayName.text.trim();
    final real = _realName.text.trim();
    return display != widget.currentDisplayName ||
        real != (widget.currentRealName ?? '');
  }

  /// Validity checked without surfacing errors — the button reflects whether
  /// a submit COULD succeed; the messages appear only once one is attempted.
  bool get _isValid =>
      Validators.validateDisplayName(_displayName.text) == null &&
      Validators.validateRealName(_realName.text) == null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave(
      displayName: _displayName.text,
      realName: _realName.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !widget.saving && _isDirty && _isValid;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _displayNameField(context),
          QeranSpacing.vs16,
          _realNameField(context),
          QeranSpacing.vs24,
          QeranButton(
            label: LocaleKeys.settings_save_changes.t(context),
            variant: QeranButtonVariant.primaryWine,
            loading: widget.saving,
            onPressed: canSave ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _displayNameField(BuildContext context) => QeranTextField(
    controller: _displayName,
    label: LocaleKeys.profile_name_display_label.t(context),
    hint: LocaleKeys.profile_name_input_hint.t(context),
    enabled: !widget.saving,
    maxLength: Validators.displayNameMax,
    textInputAction: TextInputAction.next,
    validator: Validators.validateDisplayName,
    // Rebuild so Save tracks whether either name has actually changed.
    onChanged: (_) => setState(() {}),
  );

  Widget _realNameField(BuildContext context) => QeranTextField(
    controller: _realName,
    label: LocaleKeys.profile_name_real_label.t(context),
    hint: LocaleKeys.profile_name_real_hint.t(context),
    enabled: !widget.saving,
    maxLength: Validators.realNameMax,
    textInputAction: TextInputAction.done,
    validator: Validators.validateRealName,
    onChanged: (_) => setState(() {}),
    onSubmitted: (_) => _submit(),
  );
}
