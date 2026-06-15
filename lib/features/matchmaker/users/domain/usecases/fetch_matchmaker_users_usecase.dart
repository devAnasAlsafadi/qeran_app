import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_users_list.dart';
import '../entities/matchmaker_users_page.dart';
import '../repositories/matchmaker_users_repository.dart';

class FetchMatchmakerUsersUseCase {
  final MatchmakerUsersRepository _repository;
  const FetchMatchmakerUsersUseCase(this._repository);

  Future<Either<Failure, MatchmakerUsersPage>> call({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
    int? planId,
  }) =>
      _repository.getUsers(
        list: list,
        page: page,
        pageSize: pageSize,
        planId: planId,
      );
}
