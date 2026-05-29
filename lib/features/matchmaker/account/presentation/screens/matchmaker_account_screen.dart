import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Placeholder for the matchmaker account / settings screen. M6 will
/// replace the body with the profile view + edit name / change photo /
/// change password / deactivate flows backed by `/matchmaker/me`.
class MatchmakerAccountScreen extends StatelessWidget {
  const MatchmakerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_account_title.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.person_outline_rounded,
        title: LocaleKeys.matchmaker_empty_account_title.t(context),
        message: LocaleKeys.matchmaker_empty_account_message.t(context),
      ),
    );
  }
}
