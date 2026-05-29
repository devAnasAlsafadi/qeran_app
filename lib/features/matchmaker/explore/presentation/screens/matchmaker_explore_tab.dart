import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';

/// Placeholder for the matchmaker explore tab. M5 will replace the body
/// with search/grid/filter UI backed by `GET /matchmaker/explore`.
class MatchmakerExploreTab extends StatelessWidget {
  const MatchmakerExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_explore.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.travel_explore_outlined,
        title: LocaleKeys.matchmaker_empty_explore_title.t(context),
        message: LocaleKeys.matchmaker_empty_explore_message.t(context),
      ),
    );
  }
}
