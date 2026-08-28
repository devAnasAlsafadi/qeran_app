import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../blocs/match_actions_cubit.dart';
import '../blocs/match_actions_state.dart';
import '../blocs/matchmaker_inquiry_cubit.dart';
import '../blocs/matchmaker_inquiry_state.dart';
import '../widgets/match_card.dart';

/// One row of the Matches list: a [MatchCardWidget] with every action wired
/// to the cubit that owns it.
///
/// Its own widget rather than a closure inside the list, because it is where
/// all three cubits meet and it had grown past what an `itemBuilder` should
/// hold. Both action cubits are read HERE rather than threaded down from the
/// screen, so an action or an inquiry rebuilds the affected cards and not the
/// whole tab — the screen only LISTENS to them, for snackbars.
///
/// ⚠️ Two id namespaces are in scope at once. `likeRequestId` is the CARD's
/// id and the one photo-exchange requests, formal-step requests and cancel
/// are keyed by at the case level; `pendingPhotoExchange.id` and
/// `pendingFormalStep.id` identify a request INSIDE the case. All three are
/// ints, so a mix-up compiles and reaches a real endpoint with a real id.
class MatchCardRow extends StatelessWidget {
  const MatchCardRow({
    super.key,
    required this.card,
    required this.onOpenGallery,
    required this.onOpenProfile,
  });

  final MatchCard card;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final actionsCubit = context.read<MatchActionsCubit>();
    final pendingId = card.pendingPhotoExchange?.id;
    final formalStepId = card.pendingFormalStep?.id;

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
                  pendingId != null && actions.isPhotoAccepting(pendingId),
              isRejectingPhotoExchange:
                  pendingId != null && actions.isPhotoRejecting(pendingId),
              onOpenGallery: card.images.isEmpty ? null : onOpenGallery,
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
              // Keyed by the FORMAL-STEP id, not the like id above.
              onAcceptFormalStep: actionsCubit.acceptFormalStep,
              onRejectFormalStep: actionsCubit.rejectFormalStep,
              isAcceptingFormalStep:
                  formalStepId != null &&
                  actions.isFormalStepAccepting(formalStepId),
              isRejectingFormalStep:
                  formalStepId != null &&
                  actions.isFormalStepRejecting(formalStepId),
              // Back to the LIKE id, deliberately: cancel ends the CASE that
              // the formal-step request above lives inside, and the two sit
              // four lines apart.
              onCancelCase: () => actionsCubit.cancelCase(card.likeRequestId),
              isCancelling: actions.isCancelling(card.likeRequestId),
              onOpenProfile: onOpenProfile,
            ),
          ),
    );
  }
}
