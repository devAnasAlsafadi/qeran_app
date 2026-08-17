import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';

/// No-results empty state that still scrolls, so pull-to-refresh works.
///
/// Two variants, mirroring the user app's `DiscoveryEmptyView`: an unfiltered
/// list simply has nothing to show, while a FILTERED list that came back empty
/// is a dead end — the filter icon is up in the controls row, and the row the
/// matchmaker wants to relax is inside a sheet they have to reopen. So the
/// filtered variant offers both exits, gated on all three being present the
/// same way `DiscoveryEmptyView._showActions` gates its pair.
///
/// "Narrowed" spans the filter sheet, the search field AND the gender segment —
/// any of the three can empty the list, and the clear action drops all of them.
class MatchmakerExploreEmptyResults extends StatelessWidget {
  const MatchmakerExploreEmptyResults({
    super.key,
    required this.onRefresh,
    required this.hasActiveFilters,
    this.onEditFilters,
    this.onClearFilters,
  });

  final Future<void> Function() onRefresh;
  final bool hasActiveFilters;
  final VoidCallback? onEditFilters;
  final VoidCallback? onClearFilters;

  bool get _showActions =>
      hasActiveFilters && onEditFilters != null && onClearFilters != null;

  @override
  Widget build(BuildContext context) {
    final filtered = hasActiveFilters;
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
              icon: filtered
                  ? Icons.filter_alt_off_outlined
                  : Icons.person_search_outlined,
              title:
                  (filtered
                          ? LocaleKeys
                                .matchmaker_explore_no_results_filtered_title
                          : LocaleKeys.matchmaker_explore_no_results_title)
                      .t(context),
              message:
                  (filtered
                          ? LocaleKeys
                                .matchmaker_explore_no_results_filtered_message
                          : LocaleKeys.matchmaker_explore_no_results_message)
                      .t(context),
              actionLabel: _showActions
                  ? LocaleKeys.matchmaker_explore_edit_filters.t(context)
                  : null,
              actionIcon: _showActions ? Icons.tune_rounded : null,
              onAction: _showActions ? onEditFilters : null,
              secondaryActionLabel: _showActions
                  ? LocaleKeys.matchmaker_explore_clear_filters.t(context)
                  : null,
              onSecondaryAction: _showActions ? onClearFilters : null,
            ),
          ),
        ),
      ),
    );
  }
}
