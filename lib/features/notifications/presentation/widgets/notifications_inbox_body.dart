import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/state/paginated_list_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/notification_item.dart';
import '../blocs/notification_read_cubit.dart';
import '../blocs/notification_read_state.dart';
import '../blocs/notifications_cubit.dart';
import 'notification_inbox_tile.dart';
import 'notifications_paginated_list.dart';

/// The inbox's list and its loading, error and empty states.
class NotificationsInboxBody extends StatelessWidget {
  const NotificationsInboxBody({
    super.key,
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final void Function(NotificationItem) onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NotificationsCubit,
      PaginatedListState<NotificationItem>
    >(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();

        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: QeranLoader());
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            icon: Icons.cloud_off_rounded,
            title: LocaleKeys.notifications_error_title.t(context),
            message: LocaleKeys.notifications_error_message.t(context),
            retryLabel: LocaleKeys.notifications_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyRefreshable(onRefresh: cubit.refresh);
        }
        final count = state.items.length;
        return NotificationsPaginatedList(
          hasMore: state.hasMore,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          // Flat divided feed: rows sit on the cream canvas, separated by
          // wine-08 hairlines (no per-row cards). The tile owns its horizontal
          // gutter so dividers align under the text.
          child: ListView.separated(
            padding: const EdgeInsets.only(
              top: QeranSpacing.s4,
              bottom: QeranSpacing.s20,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: count + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (context, index) =>
                // No divider between the last row and the load-more footer.
                index < count - 1
                ? const NotificationInboxDivider()
                : const SizedBox.shrink(),
            itemBuilder: (context, index) {
              if (index >= count) {
                return const NotificationsLoadMoreFooter();
              }
              final n = state.items[index];
              return BlocBuilder<NotificationReadCubit, NotificationReadState>(
                buildWhen: (prev, curr) =>
                    prev.isUnread(n.id) != curr.isUnread(n.id),
                builder: (context, read) => NotificationInboxTile(
                  notification: n,
                  isArabic: isArabic,
                  isUnread: read.isUnread(n.id),
                  onTap: () => onTap(n),
                ),
              );
            },
          ),
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
    return NotificationsPaginatedList(
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
              icon: Icons.notifications_none_rounded,
              title: LocaleKeys.notifications_empty_title.t(context),
              message: LocaleKeys.notifications_empty_subtitle.t(context),
            ),
          ),
        ),
      ),
    );
  }
}
