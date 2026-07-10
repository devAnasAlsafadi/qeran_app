import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../conversations/presentation/blocs/matchmaker_open_chat_state.dart';
import '../../domain/usecases/open_colleague_chat_usecase.dart';

/// Resolves the colleague↔colleague conversation for a tapped directory row.
/// A clone of `MatchmakerOpenChatCubit` that hits the colleague open-chat
/// usecase; it reuses the generic [MatchmakerOpenChatState] / outcome so the
/// host wiring is identical. [open] guards a double-tap while resolving, then
/// publishes a one-shot outcome the host turns into navigation / a snackbar.
class MatchmakerColleagueOpenChatCubit extends Cubit<MatchmakerOpenChatState> with SafeEmit<MatchmakerOpenChatState> {
  final OpenColleagueChatUseCase _openColleagueChat;

  MatchmakerColleagueOpenChatCubit({
    required OpenColleagueChatUseCase openColleagueChat,
  })  : _openColleagueChat = openColleagueChat,
        super(const MatchmakerOpenChatState());

  /// Resolves [colleagueId]'s conversation, then emits a [ready] outcome
  /// carrying the navigation payload. The peer identity is echoed from the row
  /// (the endpoint returns only the `conversationId`) so the host can build the
  /// thin conversation the chat route accepts without a re-fetch.
  Future<void> open({
    required String colleagueId,
    required String fullName,
    String? profileImageUrl,
  }) async {
    if (state.isOpening) return; // guard double-tap
    emit(MatchmakerOpenChatState(
      openingUserId: colleagueId,
      eventVersion: state.eventVersion,
    ));
    final result = await _openColleagueChat(colleagueId);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER — open colleague chat failed raw="${failure.message}"',
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
        peerUserId: colleagueId,
        peerName: fullName,
        peerImageUrl: profileImageUrl,
      )),
    );
  }
}
