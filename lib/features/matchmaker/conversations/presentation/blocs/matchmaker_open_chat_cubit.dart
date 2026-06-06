import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';

import '../../domain/usecases/open_user_chat_usecase.dart';
import 'matchmaker_open_chat_state.dart';

/// Resolves the matchmaker↔user conversation for a tapped user card's مراسلة
/// action. One shared instance per user list (factory): [open] guards a
/// double-tap while a chat is resolving, then publishes a one-shot
/// [MatchmakerOpenChatOutcome] the host turns into navigation / a snackbar.
class MatchmakerOpenChatCubit extends Cubit<MatchmakerOpenChatState> {
  final OpenUserChatUseCase _openUserChat;

  MatchmakerOpenChatCubit({required OpenUserChatUseCase openUserChat})
      : _openUserChat = openUserChat,
        super(const MatchmakerOpenChatState());

  /// Resolves [userId]'s conversation, then emits a [ready] outcome carrying
  /// the navigation payload. The peer identity is echoed from the card (the
  /// endpoint returns only the `conversationId`) so the host can build the thin
  /// conversation the chat route accepts without a re-fetch.
  Future<void> open({
    required String userId,
    required String fullName,
    String? profileImageUrl,
  }) async {
    if (state.isOpening) return; // guard double-tap
    emit(MatchmakerOpenChatState(
      openingUserId: userId,
      eventVersion: state.eventVersion,
    ));
    final result = await _openUserChat(userId);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER — open chat failed raw="${failure.message}"',
          tag: 'MATCHMAKER',
        );
        emit(MatchmakerOpenChatState(
          outcome: MatchmakerOpenChatOutcome.failure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failure.message,
        ));
      },
      (conversationId) => emit(MatchmakerOpenChatState(
        outcome: MatchmakerOpenChatOutcome.ready,
        eventVersion: state.eventVersion + 1,
        conversationId: conversationId,
        peerUserId: userId,
        peerName: fullName,
        peerImageUrl: profileImageUrl,
      )),
    );
  }
}
