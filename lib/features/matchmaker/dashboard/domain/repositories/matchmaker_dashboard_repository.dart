import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_dashboard_stats.dart';

abstract interface class MatchmakerDashboardRepository {
  /// Fetches the matchmaker's quick-stat counters. Left on transport /
  /// auth failure, Right with the parsed stats on success.
  Future<Either<Failure, MatchmakerDashboardStats>> getDashboard();
}
