import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';

/// Placeholder for the matchmaker users-management tab. M2 will replace
/// the body with three paginated sub-tabs (pending / approved-unsub /
/// approved-sub) backed by the matchmaker users endpoints.
class MatchmakerUsersTab extends StatelessWidget {
  const MatchmakerUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_users.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.groups_2_outlined,
        title: LocaleKeys.matchmaker_empty_users_title.t(context),
        message: LocaleKeys.matchmaker_empty_users_message.t(context),
      ),
    );
  }
}
