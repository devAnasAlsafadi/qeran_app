import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../blocs/matchmaker_interests_state.dart';

/// Loader / error / empty / content switch shared by all three interest tabs.
/// A loader shows only while there's no cached data yet; otherwise the cached
/// content stays put during a refresh.
class MatchmakerInterestSectionShell extends StatelessWidget {
  const MatchmakerInterestSectionShell({
    super.key,
    required this.status,
    required this.hasData,
    required this.isEmpty,
    required this.emptyTitleKey,
    required this.errorKey,
    required this.onRefresh,
    required this.onRetry,
    required this.builder,
  });

  final MatchmakerInterestsAsyncStatus status;
  final bool hasData;
  final bool isEmpty;
  final String emptyTitleKey;
  final String? errorKey;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      if (status == MatchmakerInterestsAsyncStatus.failure) {
        return QeranErrorState(
          title: LocaleKeys.matchmaker_interests_error_title.t(context),
          message: (errorKey ?? LocaleKeys.errors_generic).t(context),
          retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
          onRetry: onRetry,
        );
      }
      return const Center(child: QeranLoader());
    }
    if (isEmpty) {
      return _EmptyRefreshable(onRefresh: onRefresh, titleKey: emptyTitleKey);
    }
    return builder(context);
  }
}

/// Temporary placeholder list of minimal cards (replaced in M3f-c).
class MatchmakerInterestPlaceholderList extends StatelessWidget {
  const MatchmakerInterestPlaceholderList({
    super.key,
    required this.onRefresh,
    required this.items,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return MatchmakerPaginatedList(
      hasMore: false,
      onRefresh: onRefresh,
      onLoadMore: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s8,
          QeranSpacing.s20,
          QeranSpacing.s20,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: items,
      ),
    );
  }
}

/// Minimal placeholder row — avatar + name. Stand-in until the real read-only
/// interest cards (blur / answers / status) arrive in M3f-c.
class MatchmakerInterestPlaceholderCard extends StatelessWidget {
  const MatchmakerInterestPlaceholderCard({
    super.key,
    required this.name,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        children: [
          MatchmakerUserAvatar(url: imageUrl, size: 48),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              name,
              style: QeranTypography.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state that still scrolls so pull-to-refresh works.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({required this.onRefresh, required this.titleKey});

  final Future<void> Function() onRefresh;
  final String titleKey;

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
              icon: Icons.favorite_border_rounded,
              title: titleKey.t(context),
              message: LocaleKeys.matchmaker_interests_empty_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}
