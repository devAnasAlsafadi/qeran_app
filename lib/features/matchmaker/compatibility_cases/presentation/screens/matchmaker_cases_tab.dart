import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../colleagues/presentation/widgets/matchmaker_colleague_open_chat_host.dart';
import '../../../conversations/presentation/widgets/matchmaker_open_chat_host.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/compatibility_case.dart';
import '../blocs/matchmaker_cases_filter_cubit.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import '../widgets/matchmaker_cases_filter_bar.dart';
import '../widgets/matchmaker_cases_list_skeleton.dart';
import '../widgets/matchmaker_cases_list_view.dart';

/// Matchmaker compatibility-cases tab (M3a / F3) — a single paginated list of
/// active cases with a CLIENT-SIDE filter (status multi-select + name search)
/// over the loaded items. Tapping a card opens the detail + status-update flow.
class MatchmakerCasesTab extends StatelessWidget {
  const MatchmakerCasesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_cases.t(context),
      ),
      body: SafeArea(
        top: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<MatchmakerCasesListCubit>(
              create: (_) => sl<MatchmakerCasesListCubit>()..loadFirst(),
            ),
            BlocProvider<MatchmakerCasesFilterCubit>(
              create: (_) => MatchmakerCasesFilterCubit(),
            ),
          ],
          // Two open-chat hosts (person via users path, matchmaker via the
          // colleague path) — each provides its cubit + handles nav/snackbar so
          // an early-stage card can resolve-or-create either conversation on tap.
          child: const MatchmakerOpenChatHost(
            child: MatchmakerColleagueOpenChatHost(child: _CasesListBody()),
          ),
        ),
      ),
    );
  }
}

class _CasesListBody extends StatelessWidget {
  const _CasesListBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerCasesListCubit,
        PaginatedListState<CompatibilityCase>>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerCasesListCubit>();
        final filter = context.watch<MatchmakerCasesFilterCubit>().state;

        if (state.isLoading && state.items.isEmpty) {
          return const MatchmakerCasesListSkeleton();
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_cases_error_title.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_cases_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyRefreshable(onRefresh: cubit.refresh);
        }

        final visible = filter.apply(state.items);
        return Column(
          children: [
            MatchmakerCasesFilterBar(isActive: filter.isActive),
            Expanded(
              child: visible.isEmpty
                  ? const MatchmakerCasesFilteredEmpty()
                  : MatchmakerCasesListView(state: state, visible: visible),
            ),
          ],
        );
      },
    );
  }
}

/// Empty state that still scrolls, so pull-to-refresh works on an empty list.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return MatchmakerPaginatedList(
      hasMore: false,
      onRefresh: onRefresh,
      onLoadMore: () async {},
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: QeranEmptyState(
              icon: Icons.handshake_outlined,
              title: LocaleKeys.matchmaker_empty_cases_title.t(context),
              message: LocaleKeys.matchmaker_empty_cases_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}
