import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/photo_view_permission.dart';
import '../entities/photo_view_session.dart';

abstract interface class PhotoViewRepository {
  Future<Either<Failure, PhotoViewPermission>> getPermission(
    String targetUserId,
  );

  Future<Either<Failure, PhotoViewSession>> beginView(int photoExchangeId);
}
