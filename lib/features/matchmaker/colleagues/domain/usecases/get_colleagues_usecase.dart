import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_colleagues_page.dart';
import '../repositories/matchmaker_colleagues_repository.dart';

/// Fetches one page of the colleague directory — the list a matchmaker browses
/// to start a chat with another matchmaker.
class GetColleaguesUseCase {
  final MatchmakerColleaguesRepository _repository;
  const GetColleaguesUseCase(this._repository);

  Future<Either<Failure, MatchmakerColleaguesPage>> call({
    required int page,
    required int pageSize,
  }) =>
      _repository.getColleagues(page: page, pageSize: pageSize);
}
