import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../core/widgets/paginated_list.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_inbox_tile.dart'
    show NotificationInboxDivider;
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_notification.dart';
import '../blocs/matchmaker_notification_read_cubit.dart';
import '../blocs/matchmaker_notifications_cubit.dart';
import 'matchmaker_notification_tile.dart';

/// The inbox's rows: loading, error, empty (still pull-to-refresh), or the
/// paged list of [MatchmakerNotificationTile]s, each lifted while unread.
class MatchmakerNotificationsList extends StatelessWidget {
  const MatchmakerNotificationsList({
    super.key,
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final void Function(MatchmakerNotification) onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      MatchmakerNotificationsCubit,
      PaginatedListState<MatchmakerNotification>
    >(builder: _state);
  }

  Widget _state(
    BuildContext context,
    PaginatedListState<MatchmakerNotification> state,
  ) {
    final cubit = context.read<MatchmakerNotificationsCubit>();
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: QeranLoader());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return QeranErrorState(
        icon: Icons.cloud_off_rounded,
        title: LocaleKeys.matchmaker_notifications_error_title.t(context),
        message: state.errorMessage!.t(context),
        retryLabel: LocaleKeys.matchmaker_notifications_retry.t(context),
        onRetry: cubit.loadFirst,
      );
    }
    if (state.items.isEmpty) {
      return _EmptyRefreshable(onRefresh: cubit.refresh);
    }
    return PaginatedList(
      hasMore: state.hasMore,
      onRefresh: cubit.refresh,
      onLoadMore: cubit.loadMore,
      child: _list(state),
    );
  }

  /// Flat divided feed matching the user inbox (screen 13): paper rows
  /// separated by wine-08 hairlines (no per-row cards). The tile owns its
  /// horizontal gutter so dividers align under the text.
  Widget _list(PaginatedListState<MatchmakerNotification> state) {
    final count = state.items.length;
    return ListView.separated(
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
      itemBuilder: (context, index) =>
          index >= count ? const LoadMoreFooter() : _row(state.items[index]),
    );
  }

  /// Rebuilds once, when the stored watermark arrives from prefs. It is
  /// frozen for the rest of the visit by design.
  Widget _row(MatchmakerNotification n) =>
      BlocBuilder<MatchmakerNotificationReadCubit, int>(
        buildWhen: (prev, curr) => (n.id > prev) != (n.id > curr),
        builder: (context, watermark) => MatchmakerNotificationTile(
          notification: n,
          isArabic: isArabic,
          isUnread: n.id > watermark,
          onTap: () => onTap(n),
        ),
      );
}

/// Empty state that still scrolls, so pull-to-refresh works on an empty list.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return PaginatedList(
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
              title: LocaleKeys.matchmaker_empty_notifications_title.t(context),
              message: LocaleKeys.matchmaker_empty_notifications_message.t(
                context,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
