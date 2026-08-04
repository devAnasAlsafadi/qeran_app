import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/legal/domain/entities/legal_document_type.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Subscription binding line for the purchase surface: a sentence stating that
/// subscribing agrees to the Terms of Service and Privacy Policy, with each
/// document separately tappable.
///
/// Apple guideline 3.1.2(a) requires functional Terms of Use (EULA) and Privacy
/// Policy links wherever an auto-renewable subscription is sold; a missing link
/// is a routine rejection. Both open the in-app [LegalScreen] on the matching
/// document — the same route the registration oath uses — so there is no
/// WebView and no external browser hop.
class LegalLinksRow extends StatefulWidget {
  const LegalLinksRow({super.key});

  @override
  State<LegalLinksRow> createState() => _LegalLinksRowState();
}

class _LegalLinksRowState extends State<LegalLinksRow> {
  // Owned + disposed here (recognizers leak if left dangling).
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegal(LegalDocumentType.termsAndConditions);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openLegal(LegalDocumentType.privacyPolicy);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
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
    final linkStyle = QeranTypography.caption.copyWith(
      color: QeranColors.wine,
      fontWeight: FontWeight.w700,
    );
    return Text.rich(
      TextSpan(
        style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
        children: [
          TextSpan(
            text: LocaleKeys.subscriptions_legal_binding_line.t(context),
          ),
          TextSpan(
            text: LocaleKeys.auth_terms_of_service.t(context),
            style: linkStyle,
            recognizer: _termsTap,
          ),
          TextSpan(text: LocaleKeys.auth_policy_and.t(context)),
          TextSpan(
            text: LocaleKeys.auth_privacy_policy.t(context),
            style: linkStyle,
            recognizer: _privacyTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
