import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/app_text_form_field.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Bottom sheet that collects the rejection reason. Returns the trimmed
/// text (popped result) on submit, or `null` when dismissed. The reason is
/// forwarded to the user verbatim as a chat message — NO prefix — so the
/// matchmaker writes the complete message here.
Future<String?> showRejectReasonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    useSafeArea: true,
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
      setState(() => _error =
          LocaleKeys.matchmaker_profile_reject_validation_empty.t(context));
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.domeTop,
          boxShadow: QeranShadows.e3,
        ),
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s24,
          QeranSpacing.s12,
          QeranSpacing.s24,
          QeranSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            QeranSpacing.vs20,
            Text(
              LocaleKeys.matchmaker_profile_reject_title.t(context),
              style: QeranTypography.headline,
            ),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.matchmaker_profile_reject_subtitle.t(context),
              style: QeranTypography.body,
            ),
            QeranSpacing.vs16,
            AppTextFormField(
              controller: _controller,
              hintText: LocaleKeys.matchmaker_profile_reject_hint.t(context),
              obscureText: false,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 5,
              maxLength: 500,
              errorMsg: _error,
              fillColor: QeranColors.creamSurface,
              onChange: (_) {
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: QeranColors.wine.withValues(alpha: 0.25),
          borderRadius: QeranRadii.pill,
        ),
      ),
    );
  }
}
