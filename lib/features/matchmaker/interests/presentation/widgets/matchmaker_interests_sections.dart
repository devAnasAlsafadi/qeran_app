import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_interests_cubit.dart';
import '../blocs/matchmaker_interests_state.dart';
import 'matchmaker_interest_section_shell.dart';

/// The active-matches tab. M3f-b renders minimal placeholder cards to prove the
/// cubit→screen→tab flow; the real read-only match cards + inline archive land
/// in M3f-c.
class MatchmakerMatchesSection extends StatelessWidget {
  const MatchmakerMatchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerInterestsCubit, MatchmakerInterestsState>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerInterestsCubit>();
        final matches = state.matches ?? const [];
        return MatchmakerInterestSectionShell(
          status: state.matchesStatus,
          hasData: state.matches != null,
          isEmpty:
              matches.isEmpty && (state.matchesArchived?.isEmpty ?? true),
          emptyTitleKey: LocaleKeys.matchmaker_interests_empty_matches_title,
          errorKey: state.matchesErrorKey,
          onRefresh: cubit.refresh,
          onRetry: cubit.loadMatches,
          builder: (_) => MatchmakerInterestPlaceholderList(
            onRefresh: cubit.refresh,
            items: [
              for (final m in matches)
                MatchmakerInterestPlaceholderCard(
                  name: m.name,
                  imageUrl: m.isLocked ? null : m.primaryImage?.url,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The "received likes" tab (lazy). Placeholder list for M3f-b.
class MatchmakerIncomingLikesSection extends StatelessWidget {
  const MatchmakerIncomingLikesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _LikesSection(
      titleKey: LocaleKeys.matchmaker_interests_empty_incoming_title,
      select: (s) => s.incoming,
      status: (s) => s.incomingStatus,
      errorKey: (s) => s.incomingErrorKey,
      onRetry: (c) => c.loadIncoming,
    );
  }
}

/// The "sent likes" tab (lazy). Placeholder list for M3f-b.
class MatchmakerOutgoingLikesSection extends StatelessWidget {
  const MatchmakerOutgoingLikesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _LikesSection(
      titleKey: LocaleKeys.matchmaker_interests_empty_outgoing_title,
      select: (s) => s.outgoing,
      status: (s) => s.outgoingStatus,
      errorKey: (s) => s.outgoingErrorKey,
      onRetry: (c) => c.loadOutgoing,
    );
  }
}

/// Shared body for the two like tabs — they differ only in which slot they read.
class _LikesSection extends StatelessWidget {
  const _LikesSection({
    required this.titleKey,
    required this.select,
    required this.status,
    required this.errorKey,
    required this.onRetry,
  });

  final String titleKey;
  final dynamic Function(MatchmakerInterestsState) select;
  final MatchmakerInterestsAsyncStatus Function(MatchmakerInterestsState) status;
  final String? Function(MatchmakerInterestsState) errorKey;
  final VoidCallback Function(MatchmakerInterestsCubit) onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerInterestsCubit, MatchmakerInterestsState>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerInterestsCubit>();
        final activity = select(state);
        return MatchmakerInterestSectionShell(
          status: status(state),
          hasData: activity != null,
          isEmpty: activity?.isEmpty ?? true,
          emptyTitleKey: titleKey,
          errorKey: errorKey(state),
          onRefresh: cubit.refresh,
          onRetry: onRetry(cubit),
          builder: (_) => MatchmakerInterestPlaceholderList(
            onRefresh: cubit.refresh,
            items: [
              for (final like in activity!.pending)
                MatchmakerInterestPlaceholderCard(
                  name: like.name,
                  imageUrl: like.isLocked ? null : like.image?.url,
                ),
            ],
          ),
        );
      },
    );
  }
}
