import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_like_activity.dart';
import '../blocs/matchmaker_interests_cubit.dart';
import '../blocs/matchmaker_interests_state.dart';
import 'matchmaker_interest_archive_card.dart';
import 'matchmaker_interest_like_card.dart';
import 'matchmaker_interest_match_card.dart';
import 'matchmaker_interest_section_shell.dart';

/// The active-matches tab: active matches, then an inline "الأرشيف" section
/// (archived matches) below when present.
class MatchmakerMatchesSection extends StatelessWidget {
  const MatchmakerMatchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerInterestsCubit, MatchmakerInterestsState>(
      builder: (context, state) {
        final cubit = context.read<MatchmakerInterestsCubit>();
        final matches = state.matches ?? const [];
        final archived = state.matchesArchived ?? const [];
        return MatchmakerInterestSectionShell(
          status: state.matchesStatus,
          hasData: state.matches != null,
          isEmpty: matches.isEmpty && archived.isEmpty,
          emptyTitleKey: LocaleKeys.matchmaker_interests_empty_matches_title,
          errorKey: state.matchesErrorKey,
          onRefresh: cubit.refresh,
          onRetry: cubit.loadMatches,
          builder: (_) => MatchmakerInterestList(
            onRefresh: cubit.refresh,
            children: [
              for (final m in matches) MatchmakerInterestMatchCard(match: m),
              if (archived.isNotEmpty) ...[
                const MatchmakerInterestSectionHeader(
                  titleKey: LocaleKeys.matchmaker_interests_section_archive,
                ),
                for (final a in archived)
                  MatchmakerInterestArchiveCard(item: a),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The "received likes" tab (lazy).
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

/// The "sent likes" tab (lazy).
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

/// Shared body for the two like tabs — pending likes, then an inline "الأرشيف"
/// section (archived likes) below when present. They differ only in which slot
/// they read.
class _LikesSection extends StatelessWidget {
  const _LikesSection({
    required this.titleKey,
    required this.select,
    required this.status,
    required this.errorKey,
    required this.onRetry,
  });

  final String titleKey;
  final MatchmakerLikeActivity? Function(MatchmakerInterestsState) select;
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
          builder: (_) => MatchmakerInterestList(
            onRefresh: cubit.refresh,
            children: [
              for (final like in activity!.pending)
                MatchmakerInterestLikeCard(like: like),
              if (activity.archived.isNotEmpty) ...[
                const MatchmakerInterestSectionHeader(
                  titleKey: LocaleKeys.matchmaker_interests_section_archive,
                ),
                for (final like in activity.archived)
                  MatchmakerInterestLikeCard(like: like),
              ],
            ],
          ),
        );
      },
    );
  }
}
