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

  /// PERMANENT account deletion (`DELETE /matchmaker/me/account`).
  Future<Either<Failure, Unit>> deleteAccount();

  /// The success value is the new token the change answers with, if any.
  Future<Either<Failure, String?>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
