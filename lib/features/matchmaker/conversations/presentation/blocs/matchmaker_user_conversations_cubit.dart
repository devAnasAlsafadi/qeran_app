import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/matchmaker_conversation.dart';
import '../../domain/usecases/get_user_conversations_usecase.dart';

/// Owns the paginated list of the matchmaker's conversations with users.
/// Pagination, refresh and load-more come from [PaginatedListCubitMixin];
/// this class only wires the fetch under the mixin's throw-on-failure
/// contract.
class MatchmakerUserConversationsCubit
    extends Cubit<PaginatedListState<MatchmakerConversation>>
    with PaginatedListCubitMixin<MatchmakerConversation> {
  final GetUserConversationsUseCase _getConversations;

  MatchmakerUserConversationsCubit({
    required GetUserConversationsUseCase getConversations,
  })  : _getConversations = getConversations,
        super(const PaginatedListState());

  @override
  Future<({List<MatchmakerConversation> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getConversations(page: page, pageSize: pageSize);
    return result.fold(
      (failure) => throw _ConversationsFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }
}

class _ConversationsFetchException implements Exception {
  const _ConversationsFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
