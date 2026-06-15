import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_users_list.dart';
import '../entities/matchmaker_users_page.dart';
import '../entities/subscription_plan.dart';

abstract interface class MatchmakerUsersRepository {
  /// Fetches one page of [list]. Left on transport / auth failure, Right
  /// with the parsed page on success. [planId] filters the subscribed list
  /// to one plan server-side (ignored by the other lists).
  Future<Either<Failure, MatchmakerUsersPage>> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
    int? planId,
  });

  /// Fetches the dynamic plan list backing the مشتركون filter rail.
  Future<Either<Failure, List<SubscriptionPlan>>> getSubscriptionPlans();
}
