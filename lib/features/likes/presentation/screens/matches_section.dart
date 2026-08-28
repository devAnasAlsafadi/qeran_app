import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/other_profile_seed.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../blocs/match_actions_cubit.dart';
import '../blocs/match_actions_state.dart';
import '../blocs/matchmaker_inquiry_cubit.dart';
import '../blocs/matchmaker_inquiry_state.dart';
import '../widgets/likes_empty_state.dart';
import '../widgets/likes_error_view.dart';
import '../widgets/likes_loading_view.dart';
import '../widgets/match_card.dart';
import '../widgets/match_gallery_sheet.dart';
import '../widgets/match_journey_scope.dart';

/// Matches tab — active matches (post-acceptance) across stages 0/1/2.
class MatchesSection extends StatelessWidget {
  final LikesState state;

  const MatchesSection({super.key, required this.state});

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
        return BlocBuilder<MatchActionsCubit, MatchActionsState>(
          // ONLY the open journey. The in-flight sets in this same state are
          // read per card further down, and rebuilding the scope for them
          // would tear down and rebuild the whole list on every tap.
          buildWhen: (a, b) =>
              a.openJourneyLikeRequestId != b.openJourneyLikeRequestId,
          builder: (context, actions) => MatchJourneyScope(
            // Read from the cubit, not held here: `loadMatches` flips the tab
            // to `loading` before it fetches, so the list below is destroyed
            // and rebuilt on every pull-to-refresh and every gallery close.
            // State living down there would close the open card each time.
            openLikeRequestId: actions.openJourneyLikeRequestId,
            onOpenChanged: (id, open) =>
                context.read<MatchActionsCubit>().openJourney(open ? id : null),
            child: _MatchesList(
              matches: matches,
              state: state,
              onRefresh: cubit.loadMatches,
            ),
          ),
        );
    }
  }
}

class _MatchesList extends StatelessWidget {
  final List<MatchCard> matches;
  final LikesState state;
  final Future<void> Function() onRefresh;

  const _MatchesList({
    required this.matches,
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LikesCubit>();
    final actionsCubit = context.read<MatchActionsCubit>();
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: () => onRefresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        // Bottom-nav clearance so the last card clears the floating nav island
        // + gesture inset (canonical value from the nav widget).
        padding: EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s12,
          QeranSpacing.s20,
          QeranBottomNav.contentClearance(context),
        ),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final card = matches[index];
          final pendingId = card.pendingPhotoExchange?.id;
          final formalStepId = card.pendingFormalStep?.id;
          // Both other cubits are read HERE rather than threaded down from
          // the screen, so an action or an inquiry rebuilds the cards and not
          // the tab. The screen only LISTENS to them, for snackbars.
          return BlocBuilder<MatchActionsCubit, MatchActionsState>(
            builder: (context, actions) =>
                BlocBuilder<MatchmakerInquiryCubit, MatchmakerInquiryState>(
                  builder: (context, inquiry) => MatchCardWidget(
                    card: card,
                    onRequestPhotoExchange: () =>
                        actionsCubit.requestPhotoExchange(card.likeRequestId),
                    isRequestingPhotoExchange: actions.isPhotoRequesting(
                      card.likeRequestId,
                    ),
                    onAcceptPhotoExchange: pendingId == null
                        ? null
                        : () => actionsCubit.acceptPhotoExchange(pendingId),
                    onRejectPhotoExchange: pendingId == null
                        ? null
                        : () => actionsCubit.rejectPhotoExchange(pendingId),
                    isAcceptingPhotoExchange:
                        pendingId != null &&
                        actions.isPhotoAccepting(pendingId),
                    isRejectingPhotoExchange:
                        pendingId != null &&
                        actions.isPhotoRejecting(pendingId),
                    onOpenGallery: card.images.isEmpty
                        ? null
                        : () => _openGallery(context, card, cubit),
                    onContactMatchmaker: () =>
                        context.read<MatchmakerInquiryCubit>().send(
                          card,
                          LocaleKeys.likes_matches_inquiry_message.t(context),
                        ),
                    isInquirySending: inquiry.isSending(card.likeRequestId),
                    isInquirySent: inquiry.isSent(card.likeRequestId),
                    onFormalStep: () =>
                        actionsCubit.sendFormalStep(card.likeRequestId),
                    isFormalStepSending: actions.isFormalStepSending(
                      card.likeRequestId,
                    ),
                    // Keyed by the FORMAL-STEP id, not the like id above — the two
                    // sit side by side here and index different things.
                    onAcceptFormalStep: actionsCubit.acceptFormalStep,
                    onRejectFormalStep: actionsCubit.rejectFormalStep,
                    isAcceptingFormalStep:
                        formalStepId != null &&
                        actions.isFormalStepAccepting(formalStepId),
                    isRejectingFormalStep:
                        formalStepId != null &&
                        actions.isFormalStepRejecting(formalStepId),
                    onOpenProfile: () => _openProfile(context, card),
                  ),
                ),
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

  Future<void> _openGallery(
    BuildContext context,
    MatchCard card,
    LikesCubit cubit,
  ) async {
    await showMatchGallerySheet(
      context,
      images: card.images,
      targetUserId: card.otherUserId,
    );
    // isBlurred becomes true after consumption; refresh so the card removes
    // the reveal action and never offers a second opening.
    await cubit.loadMatches();
  }
}
