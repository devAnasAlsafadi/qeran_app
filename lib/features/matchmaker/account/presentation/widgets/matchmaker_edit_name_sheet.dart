import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Minimal edit-name bottom sheet (S1b). Collects a trimmed, ≤100-char name and
/// pops it; the caller drives the actual PUT + outcome toast. S1c formalizes
/// this (inline VALIDATION_ERROR display) and adds the change-password sheet.
Future<String?> showMatchmakerEditNameSheet(
  BuildContext context, {
  required String currentName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => _EditNameSheet(currentName: currentName),
  );
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.currentName});

  final String currentName;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s20 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: QeranSheetHandle()),
          QeranSpacing.vs16,
          Text(
            LocaleKeys.matchmaker_account_edit_name_title.t(context),
            style: QeranTypography.title,
          ),
          QeranSpacing.vs16,
          QeranTextField(
            controller: _controller,
            hint: LocaleKeys.matchmaker_account_name_hint.t(context),
            textInputAction: TextInputAction.done,
            maxLength: 100,
            onSubmitted: (_) => _save(),
          ),
          QeranSpacing.vs20,
          QeranButton(
            label: LocaleKeys.matchmaker_account_save.t(context),
            variant: QeranButtonVariant.primaryWine,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
