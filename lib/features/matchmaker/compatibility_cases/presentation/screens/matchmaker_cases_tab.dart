import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';

/// Placeholder for the matchmaker compatibility-cases tab. M3 will
/// replace the body with the paginated cases list + status-update flow
/// backed by `GET /matchmaker/compatibility-cases`.
class MatchmakerCasesTab extends StatelessWidget {
  const MatchmakerCasesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_cases.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.handshake_outlined,
        title: LocaleKeys.matchmaker_empty_cases_title.t(context),
        message: LocaleKeys.matchmaker_empty_cases_message.t(context),
      ),
    );
  }
}
