import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';

/// Empty state that still scrolls, so pull-to-refresh works on an empty list.
/// Shared by every matchmaker user list (and the plan-filtered subscribed
/// list, where an empty plan shows this in place of cards).
class MatchmakerUsersEmptyRefreshable extends StatelessWidget {
  const MatchmakerUsersEmptyRefreshable({
    super.key,
    required this.onRefresh,
    required this.title,
    required this.message,
  });

  final Future<void> Function() onRefresh;
  final String title;
  final String message;

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
              icon: Icons.people_outline_rounded,
              title: title,
              message: message,
            ),
          ),
        ),
      ),
    );
  }
}
