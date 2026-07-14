import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
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
          icon: Icons.cloud_off_rounded,
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

/// Pull-to-refresh ListView shell for an interests tab. The caller passes the
/// already-built rows (active cards, then optionally an archive header + cards).
class MatchmakerInterestList extends StatelessWidget {
  const MatchmakerInterestList({
    super.key,
    required this.onRefresh,
    required this.children,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> children;

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
        children: children,
      ),
    );
  }
}

/// Inline section divider label (e.g. "الأرشيف") between active rows and the
/// archived rows. Horizontal padding is inherited from the list.
class MatchmakerInterestSectionHeader extends StatelessWidget {
  const MatchmakerInterestSectionHeader({super.key, required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: QeranSpacing.s8,
        bottom: QeranSpacing.s12,
      ),
      child: Row(
        children: [
          Text(
            titleKey.t(context),
            style: QeranTypography.subtitle.copyWith(color: QeranColors.wine),
          ),
          QeranSpacing.hs8,
          const Expanded(child: Divider(color: QeranColors.divider, height: 1)),
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
