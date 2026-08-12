import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/usecases/get_conversations_usecase.dart';

/// App-scoped unread indicator for the user's matchmaker conversation.
/// The server remains the source of truth through each conversation's
/// `unreadCount`; opening Messages clears the indicator optimistically while
/// the conversation screen sends the read acknowledgement.
class ChatUnreadCubit extends Cubit<int> with SafeEmit<int> {
  ChatUnreadCubit({required GetConversationsUseCase getConversations})
    : _getConversations = getConversations,
      super(0);

  final GetConversationsUseCase _getConversations;

  Future<void> refresh() async {
    final result = await _getConversations();
    result.fold((_) {}, (conversations) {
      final unread = conversations.fold<int>(
        0,
        (sum, conversation) => sum + conversation.unreadCount,
      );
      if (!isClosed) emit(unread);
    });
  }

  void clear() {
    if (!isClosed && state != 0) emit(0);
  }
}
