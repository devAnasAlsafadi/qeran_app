import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/other_profile_seed.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../widgets/likes_empty_state.dart';
import '../widgets/likes_error_view.dart';
import '../widgets/likes_loading_view.dart';
import '../widgets/match_card.dart';
import '../widgets/match_gallery_sheet.dart';

/// Matches tab — active matches (post-acceptance) across stages 0/1/2.
class MatchesSection extends StatelessWidget {
  final LikesState state;
  final void Function(BuildContext context, String? conversationId)
      onContactMatchmaker;

  const MatchesSection({
    super.key,
    required this.state,
    required this.onContactMatchmaker,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LikesCubit>();
    switch (state.matchesStatus) {
      case LikesAsyncStatus.initial:
      case LikesAsyncStatus.loading:
        return const LikesLoadingView();
      case LikesAsyncStatus.failure:
        return LikesErrorView(onRetry: cubit.loadMatches);
      case LikesAsyncStatus.loaded:
        final matches = state.matches ?? const [];
        if (matches.isEmpty) {
          return LikesEmptyState(
            icon: Icons.handshake_outlined,
            titleKey: LocaleKeys.likes_matches_empty_title,
            subtitleKey: LocaleKeys.likes_matches_empty_subtitle,
          );
        }
        return _MatchesList(
          matches: matches,
          state: state,
          onRefresh: cubit.loadMatches,
          onContactMatchmaker: onContactMatchmaker,
        );
    }
  }
}

class _MatchesList extends StatelessWidget {
  final List<MatchCard> matches;
  final LikesState state;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext context, String? conversationId)
      onContactMatchmaker;

  const _MatchesList({
    required this.matches,
    required this.state,
    required this.onRefresh,
    required this.onContactMatchmaker,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LikesCubit>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navReserve = 96.0;
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: () => onRefresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s12,
          QeranSpacing.s20,
          bottomInset + navReserve,
        ),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final card = matches[index];
          final pendingId = card.pendingPhotoExchange?.id;
          return MatchCardWidget(
            card: card,
            onRequestPhotoExchange: () =>
                cubit.requestPhotoExchange(card.likeRequestId),
            isRequestingPhotoExchange:
                state.isPhotoExchangeRequesting(card.likeRequestId),
            onAcceptPhotoExchange: pendingId == null
                ? null
                : () => cubit.acceptPhotoExchange(pendingId),
            onRejectPhotoExchange: pendingId == null
                ? null
                : () => cubit.rejectPhotoExchange(pendingId),
            isAcceptingPhotoExchange:
                pendingId != null && state.isPhotoExchangeAccepting(pendingId),
            isRejectingPhotoExchange:
                pendingId != null && state.isPhotoExchangeRejecting(pendingId),
            onPendingExpiredLocally: cubit.loadMatches,
            onOpenGallery: card.images.isEmpty
                ? null
                : () => showMatchGallerySheet(context, images: card.images),
            onContactMatchmaker: () =>
                onContactMatchmaker(context, card.conversationId),
            onFormalStep: () => cubit.sendFormalStep(
              card,
              LocaleKeys.likes_matches_formal_step_message.t(context),
            ),
            isFormalStepSending: state.isFormalStepSending(card.likeRequestId),
            isFormalStepSent: state.isFormalStepSent(card.likeRequestId),
            onOpenProfile: () => _openProfile(context, card),
          );
        },
      ),
    );
  }

  void _openProfile(BuildContext context, MatchCard card) {
    NavigationManager.navigateTo(
      context,
      RouteNames.fullProfileDetails,
      arguments: FullProfileDetailsArgs(
        userId: card.otherUserId,
        initialData: OtherProfileSeed.fromMatchCard(card),
        entry: ProfileEntrySource.matches,
      ),
    );
  }
}
