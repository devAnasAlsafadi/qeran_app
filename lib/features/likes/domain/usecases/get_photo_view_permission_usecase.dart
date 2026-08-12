import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/photo_view_permission.dart';
import '../repositories/photo_view_repository.dart';

class GetPhotoViewPermissionUseCase {
  final PhotoViewRepository _repository;

  const GetPhotoViewPermissionUseCase(this._repository);

  Future<Either<Failure, PhotoViewPermission>> call(String targetUserId) =>
      _repository.getPermission(targetUserId);
}
