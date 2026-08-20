import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/badge_counts.dart';
import '../../domain/repositories/badges_repository.dart';
import '../datasources/badges_remote_datasource.dart';

class BadgesRepositoryImpl with BaseRepository implements BadgesRepository {
  BadgesRepositoryImpl(this._remote);

  final BadgesRemoteDataSource _remote;

  @override
  Future<Either<Failure, BadgeCounts>> getBadges() =>
      executeApiCall(() => _remote.getBadges());

  @override
  Future<Either<Failure, Unit>> markTabSeen(String tabKey) =>
      executeApiCall(() async {
        await _remote.markTabSeen(tabKey);
        return unit;
      });
}
