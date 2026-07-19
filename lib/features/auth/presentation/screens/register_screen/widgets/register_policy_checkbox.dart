import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/legal/domain/entities/legal_document_type.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Registration agreement row — a DS-native oath check (no Material
/// `Checkbox`): a 20×20 box that fills gold with a wine check when accepted,
/// leading a sentence that (1) affirms the user is 18+ and (2) links out to the
/// Privacy Policy and Terms of Service. Tapping either link opens the live
/// [LegalScreen] on that document; tapping anywhere else on the row toggles
/// acceptance via a single callback.
class RegisterPolicyCheckbox extends StatefulWidget {
  final ValueNotifier<bool> acceptedPolicyNotifier;
  final VoidCallback onToggleAcceptance;

  const RegisterPolicyCheckbox({
    super.key,
    required this.acceptedPolicyNotifier,
    required this.onToggleAcceptance,
  });

  @override
  State<RegisterPolicyCheckbox> createState() => _RegisterPolicyCheckboxState();
}

class _RegisterPolicyCheckboxState extends State<RegisterPolicyCheckbox> {
  // Owned + disposed here (recognizers leak if left dangling).
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openLegal(LegalDocumentType.privacyPolicy);
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegal(LegalDocumentType.termsAndConditions);
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  void _openLegal(LegalDocumentType type) {
    NavigationManager.navigateTo(
      context,
      RouteNames.settingsTerms,
      arguments: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = QeranTypography.bodySm.copyWith(
      color: QeranColors.wine,
      fontWeight: FontWeight.w700,
    );
    return ValueListenableBuilder<bool>(
      valueListenable: widget.acceptedPolicyNotifier,
      builder: (context, acceptedPolicy, child) {
        return GestureDetector(
          onTap: widget.onToggleAcceptance,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OathBox(checked: acceptedPolicy),
              QeranSpacing.hs12,
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: QeranTypography.bodySm.copyWith(
                      color: QeranColors.inkBody,
                    ),
                    children: [
                      TextSpan(text: LocaleKeys.auth_policy_agree.t(context)),
                      TextSpan(
                        text: LocaleKeys.auth_privacy_policy.t(context),
                        style: linkStyle,
                        recognizer: _privacyTap,
                      ),
                      TextSpan(text: LocaleKeys.auth_policy_and.t(context)),
                      TextSpan(
                        text: LocaleKeys.auth_terms_of_service.t(context),
                        style: linkStyle,
                        recognizer: _termsTap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OathBox extends StatelessWidget {
  final bool checked;

  const _OathBox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: QeranMotion.fast,
      curve: QeranCurves.standard,
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? QeranColors.gold : null,
        borderRadius: QeranRadii.xsR,
        border: checked
            ? null
            : Border.all(color: QeranColors.wine40, width: 1.5),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 15, color: QeranColors.wine)
          : null,
    );
  }
}
