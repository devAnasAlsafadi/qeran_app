import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/my_matchmaker_outcome.dart';
import '../../domain/usecases/get_my_matchmaker_usecase.dart';
import 'chat_entry_state.dart';

/// Resolves `/api/chat/my-matchmaker` for the member's chat page
/// (`MyMatchmakerChatPage`). Each opening of the page builds a fresh cubit
/// and loads.
///
/// Two non-error terminal states:
/// * `ChatEntryNoMatchmaker` — backend `status:0` + `data:null`.
///   Calm empty state; user can pull-to-refresh.
/// * `ChatEntryReady` — embeds `ChatConversationScreen`.
class ChatEntryCubit extends Cubit<ChatEntryState> with SafeEmit<ChatEntryState> {
  final GetMyMatchmakerUseCase _getMyMatchmaker;

  ChatEntryCubit({required GetMyMatchmakerUseCase getMyMatchmaker})
      : _getMyMatchmaker = getMyMatchmaker,
        super(const ChatEntryInitial());

  Future<void> load() async {
    emit(const ChatEntryLoading());
    final result = await _getMyMatchmaker();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'CHAT entry — failure raw="${failure.message}"',
          tag: 'CHAT',
        );
        emit(const ChatEntryFailure());
      },
      (outcome) {
        switch (outcome) {
          case MyMatchmakerAssigned(:final info):
            emit(ChatEntryReady(info: info));
          case MyMatchmakerNotAssigned():
            emit(const ChatEntryNoMatchmaker());
          case MyMatchmakerFailure(:final errorCode, :final serverMessage):
            AppLogger.warning(
              'CHAT entry — server failure code="$errorCode" '
              'message="$serverMessage"',
              tag: 'CHAT',
            );
            emit(const ChatEntryFailure());
        }
      },
    );
  }

  /// Pull-to-refresh on the empty state and retry after a failure. Same flow
  /// as [load].
  Future<void> refresh() => load();
}
