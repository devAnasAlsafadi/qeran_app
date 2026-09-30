import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/discovery_cubit.dart';
import '../blocs/discovery_state.dart';
import 'discovery_card_skeleton.dart';
import 'discovery_daily_limit_view.dart';
import 'discovery_empty_view.dart';
import 'discovery_profile_page.dart';
import 'open_discovery_filters.dart';

/// Owns the pull-to-refresh + the state switch below the top bar. Loading /
/// failure / empty states use always-scrollable containers so
/// `RefreshIndicator` keeps working; the loaded state renders [DiscoveryProfilePage]
/// (a fixed card whose data region scrolls internally).
class DiscoveryStateBody extends StatelessWidget {
  final DiscoveryState state;
  final ValueNotifier<double> scrollOffset;
  const DiscoveryStateBody({
    super.key,
    required this.state,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    // The loaded card owns its own RefreshIndicator (it IS the scrollable);
    // wrapping it again here would nest two indicators on one gesture.
    if (state is DiscoveryLoaded &&
        !(state as DiscoveryLoaded).isEmpty &&
        !(state as DiscoveryLoaded).isExhausted) {
      return _buildContent(context);
    }
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: () => context.read<DiscoveryCubit>().refresh(),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = state;
    if (s is DiscoveryInitial || s is DiscoveryLoading) {
      return const DiscoveryCardSkeleton();
    }
    if (s is DiscoveryFailure) {
      return _ScrollableCenter(
        child: QeranErrorState(
          title: LocaleKeys.discovery_load_failed.t(context),
          message: s.message.t(context),
          retryLabel: LocaleKeys.discovery_error_retry.t(context),
          onRetry: () => context.read<DiscoveryCubit>().loadInitial(),
        ),
      );
    }
    if (s is DiscoveryLoaded) {
      if (s.isEmpty || s.isExhausted) {
        // Deck ran dry. If more pages exist, the user out-swiped the loaded
        // deck while the next page is still loading — show a loader and make
        // sure a prefetch is in flight (once exhausted `current` is null, so
        // like()/pass() no-op and the cubit can't self-recover). Scheduled
        // post-frame so the prefetch's emit never lands during this build.
        // Only the genuine end-of-list (`!hasMore`) shows the terminal empty
        // view.
        if (s.hasMore) {
          final cubit = context.read<DiscoveryCubit>();
          // A failed prefetch is terminal until the user asks again. Without
          // this branch the view re-schedules `ensurePrefetch` on every
          // rebuild — and because the failure path clears `isPrefetching`,
          // each rebuild fires another request behind an unchanging skeleton.
          if (s.prefetchError != null) {
            return _ScrollableCenter(
              child: QeranErrorState(
                title: LocaleKeys.discovery_prefetch_failed.t(context),
                message: s.prefetchError!.t(context),
                retryLabel: LocaleKeys.discovery_error_retry.t(context),
                onRetry: cubit.retryPrefetch,
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => cubit.ensurePrefetch(),
          );
          return const DiscoveryCardSkeleton();
        }
        // A filtered deck that came back empty is otherwise a dead end: the
        // filter button lives on the card photo, and there is no card.
        final cubit = context.read<DiscoveryCubit>();
        return _ScrollableCenter(
          child: DiscoveryEmptyView(
            seenEveryone: s.hasSeenEveryone,
            // Server reason OR the client's own knowledge that a filter is
            // constraining the deck. Falling back to the local flag keeps the
            // filter escape hatch alive on a backend that sends no reason at
            // all — without it, an unreported filtered-empty deck would render
            // the generic copy and no way out, the exact dead end this view
            // exists to prevent.
            filtersMatchedNobody:
                s.filtersMatchedNobody || cubit.hasActiveFilters,
            onRefresh: cubit.refresh,
            onEditFilters: cubit.hasActiveFilters
                ? () => openDiscoveryFilters(context)
                : null,
            onStartOver: cubit.resetSeen,
            startingOver: s.isResettingSeen,
          ),
        );
      }
      return DiscoveryProfilePage(loaded: s, scrollOffset: scrollOffset);
    }
    if (s is DiscoveryDailyLimit) {
      return DiscoveryDailyLimitView(resetAt: s.resetAt);
    }
    return const SizedBox.shrink();
  }
}

/// Wraps a child in an always-scrollable view so `RefreshIndicator`
/// works even when there is no real content to scroll (loading /
/// empty / error states).
class _ScrollableCenter extends StatelessWidget {
  final Widget child;
  const _ScrollableCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
