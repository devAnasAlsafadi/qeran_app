import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/matchmaker_editable_answer.dart';
import '../../domain/usecases/get_editable_answers_usecase.dart';

/// Paginated list of a user's editable text answers (pageSize 50).
/// Pagination/refresh/load-more come from [PaginatedListCubitMixin]; this
/// class wires the fetch and applies in-place row updates after a save.
class MatchmakerEditableAnswersCubit
    extends Cubit<PaginatedListState<MatchmakerEditableAnswer>>
    with PaginatedListCubitMixin<MatchmakerEditableAnswer> {
  final String userId;
  final GetEditableAnswersUseCase _getAnswers;

  MatchmakerEditableAnswersCubit({
    required this.userId,
    required GetEditableAnswersUseCase getEditableAnswers,
  })  : _getAnswers = getEditableAnswers,
        super(const PaginatedListState());

  @override
  int get pageSize => 50;

  @override
  Future<({List<MatchmakerEditableAnswer> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getAnswers(
      userId: userId,
      page: page,
      pageSize: pageSize,
    );
    return result.fold(
      (failure) => throw _AnswersFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }

  /// Replaces the answer for [questionId] in place after a successful save,
  /// so the row reflects the new text without a full refetch.
  void applyUpdate(int questionId, String newAnswer) {
    emit(state.copyWith(
      items: [
        for (final a in state.items)
          a.questionId == questionId ? a.copyWith(currentAnswer: newAnswer) : a,
      ],
    ));
  }
}

class _AnswersFetchException implements Exception {
  const _AnswersFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
