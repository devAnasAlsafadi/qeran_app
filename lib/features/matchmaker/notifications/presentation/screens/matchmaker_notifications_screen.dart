import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/state/paginated_list_state.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_inbox_tile.dart'
    show NotificationInboxDivider;
import '../../../../../generated/locale_keys.g.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../shared/data/matchmaker_notification_router.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_notification.dart';
import '../blocs/matchmaker_notification_badge_cubit.dart';
import '../blocs/matchmaker_notification_read_cubit.dart';
import '../blocs/matchmaker_notifications_cubit.dart';
import '../widgets/matchmaker_notification_tile.dart';

/// The matchmaker notification inbox (F5). Paginated list backed by
/// `GET /notifications`. On open it marks everything "seen" (clears the bell
/// badge); a row tap deep-links via [MatchmakerNotificationRouter].
///
/// Read-state is LOCAL — the backend exposes none. Two separate ideas, the
/// same split the user app makes:
/// * **seen** ([MatchmakerNotificationBadgeCubit]) clears the bell badge, on
///   open.
/// * **read** ([MatchmakerNotificationReadCubit]) lifts a row. Coarser than
///   the user app's: with no per-id endpoint there is no "mark this one read",
///   so a row is unread when it arrived since the last visit. The watermark
///   the rows render against is frozen at mount and advanced on the way OUT,
///   so arriving at the inbox doesn't erase the very thing the user came for.
class MatchmakerNotificationsScreen extends StatefulWidget {
  const MatchmakerNotificationsScreen({super.key});

  @override
  State<MatchmakerNotificationsScreen> createState() =>
      _MatchmakerNotificationsScreenState();
}

class _MatchmakerNotificationsScreenState
    extends State<MatchmakerNotificationsScreen> {
  late final MatchmakerNotificationsCubit _cubit;
  late final MatchmakerNotificationReadCubit _readCubit;

  /// Highest id the screen has loaded — the read watermark written on exit.
  int _newestLoadedId = 0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MatchmakerNotificationsCubit>()..loadFirst();
    _readCubit = sl<MatchmakerNotificationReadCubit>()..load();
    // Opening the inbox = everything seen → clears the app-bar bell badge.
    sl<MatchmakerNotificationBadgeCubit>().markAllSeen();
  }

  @override
  void dispose() {
    // On the way out, not on load: the rows stay lifted for the whole visit,
    // and the NEXT visit starts clean. Fire-and-forget — it only writes a
    // preference, and never emits, so the close below is safe.
    if (_newestLoadedId > 0) _readCubit.markAllRead(_newestLoadedId);
    _readCubit.close();
    _cubit.close();
    super.dispose();
  }

  void _rememberNewest(List<MatchmakerNotification> items) {
    for (final n in items) {
      if (n.id > _newestLoadedId) _newestLoadedId = n.id;
    }
  }

  /// Deep-link a tapped row.
  ///
  /// Chat is PUSHED on top of this inbox, so back returns here. A Cases row
  /// cannot be: the tab lives in the shell BELOW this route, so the inbox pops
  /// and hands the intent up — the same shape the user app uses. It used to
  /// fall through to a bare `break`, which meant tapping a case row in the
  /// matchmaker inbox did nothing at all.
  void _onTap(MatchmakerNotification n) {
    final link = MatchmakerNotificationRouter.parse(n.data);
    switch (link) {
      case OpenCases():
        Navigator.of(context).pop(link);
        return;
      case IgnoreDeepLink():
        return;
      case OpenUserChat(:final conversationId, :final senderName):
        NavigationManager.navigateTo(
          context,
          RouteNames.matchmakerUserChat,
          arguments: MatchmakerConversation(
            userId: '',
            fullName: senderName,
            profileImageUrl: null,
            conversationId: conversationId,
            lastMessageAt: null,
            lastMessagePreview: null,
            unreadCount: 0,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return MultiBlocProvider(
      providers: [
        BlocProvider<MatchmakerNotificationsCubit>.value(value: _cubit),
        BlocProvider<MatchmakerNotificationReadCubit>.value(value: _readCubit),
      ],
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.matchmaker_notifications_title.t(context),
        ),
        body: SafeArea(
          top: false,
          child:
              BlocListener<
                MatchmakerNotificationsCubit,
                PaginatedListState<MatchmakerNotification>
              >(
                listenWhen: (prev, curr) =>
                    prev.items.length != curr.items.length,
                listener: (_, state) => _rememberNewest(state.items),
                child: _Body(isArabic: isArabic, onTap: _onTap),
              ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.isArabic, required this.onTap});

  final bool isArabic;
  final void Function(MatchmakerNotification) onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerNotificationsCubit,
        PaginatedListState<MatchmakerNotification>>(
      builder: (context, state) {
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
        final count = state.items.length;
        return MatchmakerPaginatedList(
          hasMore: state.hasMore,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          // Flat divided feed matching the user inbox (screen 13): paper rows
          // separated by wine-08 hairlines (no per-row cards). The tile owns
          // its horizontal gutter so dividers align under the text.
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
                return const MatchmakerLoadMoreFooter();
              }
              final n = state.items[index];
              // Rebuilds once, when the stored watermark arrives from prefs.
              // It is frozen for the rest of the visit by design.
              return BlocBuilder<MatchmakerNotificationReadCubit, int>(
                buildWhen: (prev, curr) => (n.id > prev) != (n.id > curr),
                builder: (context, watermark) => MatchmakerNotificationTile(
                  notification: n,
                  isArabic: isArabic,
                  isUnread: n.id > watermark,
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
              icon: Icons.notifications_none_rounded,
              title:
                  LocaleKeys.matchmaker_empty_notifications_title.t(context),
              message:
                  LocaleKeys.matchmaker_empty_notifications_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}
