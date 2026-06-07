import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_me_image.dart';
import '../repositories/matchmaker_account_repository.dart';

/// Uploads / replaces the matchmaker's profile photo and returns the saved
/// image (jpg/jpeg/png ≤2MB enforced server-side).
class UploadAccountPhotoUseCase {
  final MatchmakerAccountRepository _repository;
  const UploadAccountPhotoUseCase(this._repository);

  Future<Either<Failure, MatchmakerMeImage>> call(File image) =>
      _repository.uploadPhoto(image);
}
