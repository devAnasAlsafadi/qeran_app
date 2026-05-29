import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Placeholder for the matchmaker notifications history screen. M6 will
/// replace the body with the paginated list backed by
/// `GET /notifications`.
class MatchmakerNotificationsScreen extends StatelessWidget {
  const MatchmakerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_notifications_title.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.notifications_none_rounded,
        title: LocaleKeys.matchmaker_empty_notifications_title.t(context),
        message: LocaleKeys.matchmaker_empty_notifications_message.t(context),
      ),
    );
  }
}
