import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_users_list.dart';
import '../entities/matchmaker_users_page.dart';

abstract interface class MatchmakerUsersRepository {
  /// Fetches one page of [list]. Left on transport / auth failure, Right
  /// with the parsed page on success.
  Future<Either<Failure, MatchmakerUsersPage>> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
  });
}
