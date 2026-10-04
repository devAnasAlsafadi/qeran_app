import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_helper_line.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../profile/presentation/blocs/name/name_cubit.dart';
import '../../../../profile/presentation/blocs/name/name_state.dart';
import '../../../../profile/presentation/screens/name/widgets/display_name_field.dart';
import 'name_gate_preview.dart';

/// The name step's form (F1–F3): why it's asked, the display-name field,
/// that the real name stays private, a comment's preview under the typed
/// name — the placeholder until one is typed — and «حفظ ومتابعة». Only the
/// display name is sent; the real name is left as it is.
class NameGateForm extends StatefulWidget {
  const NameGateForm({super.key, required this.state});

  final NameState state;

  @override
  State<NameGateForm> createState() => _NameGateFormState();
}

class _NameGateFormState extends State<NameGateForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  static const _padding = EdgeInsetsDirectional.fromSTEB(
    QeranSpacing.s20,
    QeranSpacing.s12,
    QeranSpacing.s20,
    QeranSpacing.s24,
  );

  /// In line with the field's own help line, which sits at its content
  /// padding.
  static const _noteInset = EdgeInsetsDirectional.only(start: QeranSpacing.s24);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _typed => _name.text.trim();

  bool get _canSave =>
      !widget.state.saving &&
      Validators.validateDisplayName(_typed) == null &&
      _typed != widget.state.filteredName;

  void _save() {
    if (!_canSave || !(_formKey.currentState?.validate() ?? false)) return;
    context.read<NameCubit>().save(displayName: _typed);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._intro(context),
            QeranSpacing.vs20,
            ..._field(context),
            QeranSpacing.vs20,
            NameGatePreview(
              name: _typed.isEmpty ? widget.state.displayName : _typed,
            ),
            QeranSpacing.vs24,
            QeranButton(
              label: LocaleKeys.community_name_gate_save.t(context),
              variant: QeranButtonVariant.primaryWine,
              loading: widget.state.saving,
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _intro(BuildContext context) => [
    Text(
      LocaleKeys.community_name_gate_title.t(context),
      style: QeranTypography.title,
    ),
    QeranSpacing.vs8,
    Text(
      LocaleKeys.community_name_gate_body.t(context),
      style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
    ),
  ];

  /// The field, then the line that the real name stays private.
  List<Widget> _field(BuildContext context) => [
    DisplayNameField(
      controller: _name,
      filteredName: widget.state.filteredName,
      enabled: !widget.state.saving,
      // The preview and Save follow the text.
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
    ),
    QeranSpacing.vs12,
    Padding(
      padding: _noteInset,
      child: QeranHelperLine(
        icon: Icons.lock_outline_rounded,
        text: LocaleKeys.community_name_private.t(context),
      ),
    ),
  ];
}
