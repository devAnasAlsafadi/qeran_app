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
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/notification_item.dart';
import '../blocs/notifications_cubit.dart';
import '../routing/notification_deep_link.dart';
import '../widgets/notification_inbox_tile.dart';
import '../widgets/notifications_paginated_list.dart';

/// The user-app notification inbox. A paginated list backed by
/// `GET /api/notifications`. A row tap resolves a [NotificationDeepLink] and
/// pops it back to [openNotifications], which switches the home tab; rows with
/// no destination ([NoDeepLink]) don't pop. No read-state / mark-all-read — the
/// backend exposes none (render only what the backend backs).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<NotificationsCubit>()..loadFirst();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Resolve the deep-link; actionable rows pop the intent (handled by
  /// `openNotifications`), non-actionable rows stay on the inbox.
  void _onTap(NotificationItem n) {
    final link = NotificationDeepLinkRouter.resolve(n);
    if (link is NoDeepLink) return;
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return BlocProvider<NotificationsCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.notifications_title.t(context),
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
  final void Function(NotificationItem) onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, PaginatedListState<NotificationItem>>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();

        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: QeranLoader());
        }
        if (state.errorMessage != null && state.items.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.notifications_error_title.t(context),
            message: LocaleKeys.notifications_error_message.t(context),
            retryLabel: LocaleKeys.notifications_retry.t(context),
            onRetry: cubit.loadFirst,
          );
        }
        if (state.items.isEmpty) {
          return _EmptyRefreshable(onRefresh: cubit.refresh);
        }
        return NotificationsPaginatedList(
          hasMore: state.hasMore,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s16,
              QeranSpacing.s12,
              QeranSpacing.s16,
              QeranSpacing.s20,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const NotificationsLoadMoreFooter();
              }
              final n = state.items[index];
              return NotificationInboxTile(
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
