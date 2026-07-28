import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Bottom sheet that collects the rejection reason. Returns the trimmed
/// text (popped result) on submit, or `null` when dismissed. The reason is
/// forwarded to the user verbatim as a chat message — NO prefix — so the
/// matchmaker writes the complete message here.
Future<String?> showRejectReasonSheet(BuildContext context) {
  return showQeranBottomSheet<String>(
    context: context,
    builder: (_) => const _RejectReasonSheet(),
  );
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = LocaleKeys.matchmaker_profile_reject_validation_empty.t(
          context,
        ),
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return QeranBottomSheetScaffold(
      title: LocaleKeys.matchmaker_profile_reject_title.t(context),
      // Multiline reason field — the body must scroll under the keyboard.
      scrollableBody: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s4,
          QeranSpacing.s20,
          QeranSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.matchmaker_profile_reject_subtitle.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs16,
            QeranTextField(
              controller: _controller,
              hint: LocaleKeys.matchmaker_profile_reject_hint.t(context),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 5,
              maxLength: 500,
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            QeranSpacing.vs16,
            QeranButton(
              label: LocaleKeys.matchmaker_profile_reject_submit.t(context),
              variant: QeranButtonVariant.destructive,
              onPressed: _submit,
            ),
            QeranSpacing.vs8,
            QeranButton(
              label: LocaleKeys.matchmaker_profile_action_cancel.t(context),
              variant: QeranButtonVariant.ghost,
              size: QeranButtonSize.md,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
