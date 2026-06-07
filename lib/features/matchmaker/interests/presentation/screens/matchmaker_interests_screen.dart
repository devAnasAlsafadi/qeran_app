import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import '../../domain/entities/matchmaker_interests_tab.dart';
import '../blocs/matchmaker_interests_cubit.dart';
import '../blocs/matchmaker_interests_state.dart';
import '../widgets/matchmaker_interests_header.dart';
import '../widgets/matchmaker_interests_sections.dart';

/// Read-only mirror of one viewed user's interests: a single user header above
/// three lazy tabs (active matches / received likes / sent likes). Reached only
/// from a subscribed user's card (الإهتمامات). The matchmaker observes — no
/// actions, no countdown.
class MatchmakerInterestsScreen extends StatelessWidget {
  const MatchmakerInterestsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MatchmakerInterestsCubit>(param1: userId)..primeActiveTab(),
      child: const _InterestsView(),
    );
  }
}

class _InterestsView extends StatelessWidget {
  const _InterestsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_interests_title.t(context),
      ),
      body: BlocBuilder<MatchmakerInterestsCubit, MatchmakerInterestsState>(
        builder: (context, state) {
          final cubit = context.read<MatchmakerInterestsCubit>();
          return Column(
            children: [
              if (state.user != null)
                MatchmakerInterestsHeader(user: state.user!),
              MatchmakerSegmentedTabs(
                segments: const [
                  MatchmakerSegment(
                    labelKey: LocaleKeys.matchmaker_interests_tab_matches,
                  ),
                  MatchmakerSegment(
                    labelKey: LocaleKeys.matchmaker_interests_tab_incoming,
                  ),
                  MatchmakerSegment(
                    labelKey: LocaleKeys.matchmaker_interests_tab_outgoing,
                  ),
                ],
                activeIndex: state.activeTab.index,
                onChanged: (i) =>
                    cubit.switchTab(MatchmakerInterestsTab.values[i]),
              ),
              const Expanded(
                child: _InterestsTabStack(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Keeps all three sections mounted so each tab's scroll + loaded data survive
/// tab switches; only the active index is shown.
class _InterestsTabStack extends StatelessWidget {
  const _InterestsTabStack();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerInterestsCubit, MatchmakerInterestsState>(
      buildWhen: (prev, curr) => prev.activeTab != curr.activeTab,
      builder: (context, state) {
        return IndexedStack(
          index: state.activeTab.index,
          children: const [
            MatchmakerMatchesSection(),
            MatchmakerIncomingLikesSection(),
            MatchmakerOutgoingLikesSection(),
          ],
        );
      },
    );
  }
}
