import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/state/paginated_list_state.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/notification_item.dart';
import '../blocs/notification_read_cubit.dart';
import '../blocs/notification_read_state.dart';
import '../blocs/notifications_cubit.dart';
import '../routing/notification_deep_link.dart';
import '../widgets/notification_inbox_tile.dart';
import '../widgets/notifications_paginated_list.dart';

/// The user-app notification inbox. A paginated list backed by
/// `GET /api/notifications`. A row tap resolves a [NotificationDeepLink]:
/// a chat link PUSHES the conversation on top of this screen (QER-26, so back
/// returns here); Likes / Profile links pop back to [openNotifications], which
/// switches the home tab; rows with no destination ([NoDeepLink]) don't move.
///
/// Two separate ideas, and they no longer share a source:
/// * **seen** clears the bell — a server-side count, cleared through
///   [BadgesCubit]. Marked on the way OUT, not on load, so a failed load
///   never clears a badge for notifications the user never saw.
/// * **read** ([NotificationReadCubit]) greys a row out and stays LOCAL — the
///   backend exposes no per-row read-state. A row is read once it is tapped,
///   or once "mark all as read" is used.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsCubit _cubit;
  final NotificationReadCubit _readCubit = sl<NotificationReadCubit>();

  /// Highest id the screen has loaded — the "seen" watermark written on exit,
  /// and what "mark all as read" reads up to.
  int _newestLoadedId = 0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<NotificationsCubit>()..loadFirst();
    _readCubit.load();
  }

  @override
  void dispose() {
    // On the way out, not on load: the bell clears because the user has been
    // here, while the rows they never opened stay marked unread. The guard
    // matters more than it did — mark-seen is server-side now, so clearing it
    // after a load that failed would lose the badge for good.
    if (_newestLoadedId > 0) {
      sl<BadgesCubit>().markSeen(BadgeTabKeys.notifications);
    }
    _cubit.close();
    super.dispose();
  }

  void _rememberNewest(List<NotificationItem> items) {
    for (final n in items) {
      if (n.id > _newestLoadedId) _newestLoadedId = n.id;
    }
  }

  /// Reading one: mark it, then resolve the deep-link. Non-actionable rows stay
  /// put — they still count as read, since the user opened them.
  void _onTap(NotificationItem n) {
    _readCubit.markRead(n.id);
    final link = NotificationDeepLinkRouter.resolve(n);
    switch (link) {
      case NoDeepLink():
        return;
      // QER-26: the chat is PUSHED on top of the inbox rather than popping it.
      // Popping replaced the stack — the user landed in the conversation with
      // the inbox gone and nothing to go back to. Pushing leaves
      // home → inbox → chat, so back returns to the inbox and back again to
      // where they started. The pushed chat carries its own back affordance
      // (QER-16); the tab copy does not, because a tab has nothing to pop.
      case OpenMessagesTab():
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (routeContext) => Scaffold(
              backgroundColor: QeranColors.creamCanvas,
              body: SafeArea(
                child: ChatEntryScreen(
                  onBack: () => Navigator.of(routeContext).pop(),
                ),
              ),
            ),
          ),
        );
      // Likes and Profile are bottom-nav TABS, not routes — they are still
      // handed back to `openNotifications` to switch the tab. Pushing a tab
      // body as a route would detach it from the shell it reads state from.
      case OpenLikesTab():
      case OpenProfileTab():
        Navigator.of(context).pop(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return MultiBlocProvider(
      providers: [
        BlocProvider<NotificationsCubit>.value(value: _cubit),
        // `.value` — the shared singleton must outlive this screen.
        BlocProvider<NotificationReadCubit>.value(value: _readCubit),
      ],
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.notifications_title.t(context),
          actions: const [_MarkAllReadAction()],
        ),
        body: SafeArea(
          top: false,
          child:
              BlocListener<
                NotificationsCubit,
                PaginatedListState<NotificationItem>
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

/// Clears every loaded row's unread mark in one tap.
///
/// Rendered ONLY while something is actually unread — an always-present button
/// that usually does nothing is worse than no button.
class _MarkAllReadAction extends StatelessWidget {
  const _MarkAllReadAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NotificationsCubit,
      PaginatedListState<NotificationItem>
    >(
      builder: (context, list) {
        if (list.items.isEmpty) return const SizedBox.shrink();
        return BlocBuilder<NotificationReadCubit, NotificationReadState>(
          builder: (context, read) {
            final ids = list.items.map((n) => n.id);
            if (!read.hasUnreadAmong(ids)) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: LocaleKeys.notifications_mark_all_read.t(context),
              onPressed: () => context
                  .read<NotificationReadCubit>()
                  .markAllRead(ids.reduce((a, b) => a > b ? a : b)),
            );
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.isArabic, required this.onTap});

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
