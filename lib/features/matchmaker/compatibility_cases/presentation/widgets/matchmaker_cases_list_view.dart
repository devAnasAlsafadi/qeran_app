import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/compatibility_case.dart';
import '../blocs/matchmaker_cases_filter_cubit.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import 'matchmaker_case_card.dart';

/// The populated cases list — renders the [visible] (already filtered) items
/// over the underlying paginated [state]. Pagination still operates on the full
/// loaded set; the footer shows while more pages exist.
class MatchmakerCasesListView extends StatelessWidget {
  const MatchmakerCasesListView({
    super.key,
    required this.state,
    required this.visible,
  });

  final PaginatedListState<CompatibilityCase> state;
  final List<CompatibilityCase> visible;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerCasesListCubit>();
    return MatchmakerPaginatedList(
      hasMore: state.hasMore,
      onRefresh: cubit.refresh,
      onLoadMore: cubit.loadMore,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s8,
          QeranSpacing.s20,
          QeranSpacing.s20,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: visible.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return const MatchmakerLoadMoreFooter();
          }
          final caseItem = visible[index];
          return MatchmakerCaseCard(
            caseItem: caseItem,
            onTap: () async {
              final changed = await NavigationManager.navigateTo(
                context,
                RouteNames.matchmakerCaseDetail,
                arguments: caseItem,
              );
              if (changed == true && context.mounted) {
                context.read<MatchmakerCasesListCubit>().refresh();
              }
            },
          );
        },
      ),
    );
  }
}

/// Shown when a filter is active but no loaded case matches it.
class MatchmakerCasesFilteredEmpty extends StatelessWidget {
  const MatchmakerCasesFilteredEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: QeranEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: LocaleKeys.matchmaker_cases_filter_empty_title.t(context),
            message:
                LocaleKeys.matchmaker_cases_filter_empty_message.t(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            0,
            QeranSpacing.s20,
            QeranSpacing.s20,
          ),
          child: QeranButton(
            label: LocaleKeys.matchmaker_cases_filter_clear.t(context),
            variant: QeranButtonVariant.ghost,
            onPressed: () =>
                context.read<MatchmakerCasesFilterCubit>().clear(),
          ),
        ),
      ],
    );
  }
}
