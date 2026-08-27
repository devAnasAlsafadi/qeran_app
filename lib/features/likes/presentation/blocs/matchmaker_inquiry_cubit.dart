import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';

import '../../domain/entities/match_card.dart';
import 'matchmaker_inquiry_state.dart';

/// The stage-0 "ask my matchmaker about this match" flow: share the viewed
/// profile card into the matchmaker conversation, then send the predefined
/// inquiry text. Both are required — the ticket treats a shared card with no
/// question, or a question with no card, as an incomplete inquiry.
///
/// Lifted out of `LikesCubit` because it had quietly become the only thing in
/// there that talks to chat. `sendFormalStep` used to share into the same
/// conversation and stopped when the formal step became a request to the other
/// MEMBER rather than to the matchmaker; after that, all three chat use cases
/// below served this one method and nothing noticed. Lifting it is recognising
/// what already happened, not a new decision.
///
/// It needs no reload callback, unlike the match actions. An inquiry changes
/// nothing the matches feed reports — it puts a message in a conversation —
/// so there is no list to refetch and no coupling back to `LikesCubit`.
class MatchmakerInquiryCubit extends Cubit<MatchmakerInquiryState>
    with SafeEmit<MatchmakerInquiryState> {
  final GetMyMatchmakerUseCase _getMyMatchmaker;
  final ShareProfileUseCase _shareProfile;
  final SendTextMessageUseCase _sendText;

  MatchmakerInquiryCubit({
    required GetMyMatchmakerUseCase getMyMatchmaker,
    required ShareProfileUseCase shareProfile,
    required SendTextMessageUseCase sendText,
  }) : _getMyMatchmaker = getMyMatchmaker,
       _shareProfile = shareProfile,
       _sendText = sendText,
       super(const MatchmakerInquiryState());

  /// Stage-0 inquiry. The ticket requires both the viewed profile card and
  /// the predefined inquiry text to be present before the chat is opened.
  Future<void> send(MatchCard card, String message) async {
    final id = card.likeRequestId;
    if (state.isSending(id)) return;
    if (state.isSent(id)) {
      emit(
        state.copyWith(
          event: InquiryEvent.alreadySent,
          eventVersion: state.eventVersion + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(inFlightLikeIds: {...state.inFlightLikeIds, id}),
    );
    final done = await _shareAndSend(card: card, message: message);
    if (isClosed) return;

    emit(
      state.copyWith(
        inFlightLikeIds: {...state.inFlightLikeIds}..remove(id),
        sentLikeIds: done ? {...state.sentLikeIds, id} : state.sentLikeIds,
        event: done ? InquiryEvent.success : InquiryEvent.failure,
        eventVersion: state.eventVersion + 1,
      ),
    );
  }

  Future<bool> _shareAndSend({
    required MatchCard card,
    required String message,
  }) async {
    final conversationId = await _resolveConversationId(card);
    if (conversationId == null || isClosed) return false;

    final share = await _shareProfile(
      conversationId: conversationId,
      sharedUserId: card.otherUserId,
    );
    if (isClosed) return false;

    final canSendMessage = share.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER-SEND — share failed id=${card.likeRequestId} '
          'raw="${failure.message}"',
          tag: 'MATCHES',
        );
        return false;
      },
      (outcome) => switch (outcome) {
        // A rate limit here means the same profile was shared recently. The
        // accompanying text is still required and safe to attempt.
        ShareProfileSuccess() || ShareProfileRateLimited() => true,
        _ => false,
      },
    );
    if (!canSendMessage) {
      AppLogger.warning(
        'MATCHMAKER-SEND — profile share rejected id=${card.likeRequestId}',
        tag: 'MATCHES',
      );
      return false;
    }

    final send = await _sendText(
      conversationId: conversationId,
      content: message,
    );
    if (isClosed) return false;
    return send.fold((failure) {
      AppLogger.warning(
        'MATCHMAKER-SEND — text failed id=${card.likeRequestId} '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return false;
    }, (outcome) => outcome is SendTextSuccess);
  }

  Future<int?> _resolveConversationId(MatchCard card) async {
    final embedded = int.tryParse(card.conversationId ?? '');
    if (embedded != null) return embedded;

    final result = await _getMyMatchmaker();
    if (isClosed) return null;
    return result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER-SEND — resolve failed raw="${failure.message}"',
          tag: 'MATCHES',
        );
        return null;
      },
      (outcome) => switch (outcome) {
        MyMatchmakerAssigned(:final info) => info.conversationId,
        MyMatchmakerNotAssigned() || MyMatchmakerFailure() => null,
      },
    );
  }
}
