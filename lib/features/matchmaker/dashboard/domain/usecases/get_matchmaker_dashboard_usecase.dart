import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_dashboard_stats.dart';
import '../repositories/matchmaker_dashboard_repository.dart';

class GetMatchmakerDashboardUseCase {
  final MatchmakerDashboardRepository _repository;
  const GetMatchmakerDashboardUseCase(this._repository);

  Future<Either<Failure, MatchmakerDashboardStats>> call() =>
      _repository.getDashboard();
}
