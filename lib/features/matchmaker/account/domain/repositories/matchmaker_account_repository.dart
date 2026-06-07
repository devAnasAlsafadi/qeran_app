import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_me.dart';
import '../entities/matchmaker_me_image.dart';

abstract interface class MatchmakerAccountRepository {
  Future<Either<Failure, MatchmakerMe>> getMe();

  /// [name] is already trimmed by the caller.
  Future<Either<Failure, Unit>> updateName(String name);

  Future<Either<Failure, MatchmakerMeImage>> uploadPhoto(File image);

  Future<Either<Failure, Unit>> deactivate();

  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
