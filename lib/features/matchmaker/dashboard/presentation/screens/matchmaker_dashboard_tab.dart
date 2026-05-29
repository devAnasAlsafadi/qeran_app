import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';

/// Placeholder for the matchmaker dashboard (M2 will replace the body
/// with the 5-counter stats grid backed by `GET /matchmaker/dashboard`).
class MatchmakerDashboardTab extends StatelessWidget {
  const MatchmakerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_dashboard.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.dashboard_outlined,
        title: LocaleKeys.matchmaker_empty_dashboard_title.t(context),
        message: LocaleKeys.matchmaker_empty_dashboard_message.t(context),
      ),
    );
  }
}
