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
import '../../../../../generated/locale_keys.g.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../shared/data/matchmaker_notification_router.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_notification.dart';
import '../blocs/matchmaker_notification_badge_cubit.dart';
import '../blocs/matchmaker_notifications_cubit.dart';
import '../widgets/matchmaker_notification_tile.dart';

/// The matchmaker notification inbox (F5). Paginated list backed by
/// `GET /notifications`. On open it marks everything "seen" (clears the bell
/// badge); a row tap deep-links via [MatchmakerNotificationRouter].
class MatchmakerNotificationsScreen extends StatefulWidget {
  const MatchmakerNotificationsScreen({super.key});

  @override
  State<MatchmakerNotificationsScreen> createState() =>
      _MatchmakerNotificationsScreenState();
}

class _MatchmakerNotificationsScreenState
    extends State<MatchmakerNotificationsScreen> {
  late final MatchmakerNotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MatchmakerNotificationsCubit>()..loadFirst();
    // Opening the inbox = everything seen → clears the app-bar bell badge.
    sl<MatchmakerNotificationBadgeCubit>().markAllSeen();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Deep-link a tapped row. Chat → push the shared chat screen; cases / ignore
  /// are a no-op from this pushed inbox (the shell's FCM-tap path owns
  /// tab-selection deep-links).
  void _onTap(MatchmakerNotification n) {
    switch (MatchmakerNotificationRouter.parse(n.data)) {
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
      case OpenCases():
      case IgnoreDeepLink():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return BlocProvider<MatchmakerNotificationsCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.matchmaker_notifications_title.t(context),
        ),
        body: SafeArea(
          top: false,
          child: _Body(isArabic: isArabic, onTap: _onTap),
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
            title: LocaleKeys.matchmaker_notifications_error_title.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_notifications_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyRefreshable(onRefresh: cubit.refresh);
        }
        return MatchmakerPaginatedList(
          hasMore: state.hasMore,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s12,
              QeranSpacing.s20,
              QeranSpacing.s20,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const MatchmakerLoadMoreFooter();
              }
              final n = state.items[index];
              return MatchmakerNotificationTile(
                notification: n,
                isArabic: isArabic,
                onTap: () => onTap(n),
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
