import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/photo_view_session.dart';
import '../repositories/photo_view_repository.dart';

class BeginPhotoViewUseCase {
  final PhotoViewRepository _repository;

  const BeginPhotoViewUseCase(this._repository);

  Future<Either<Failure, PhotoViewSession>> call(int photoExchangeId) =>
      _repository.beginView(photoExchangeId);
}
