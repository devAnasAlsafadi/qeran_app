import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/basic_user.dart';
import '../repositories/profile_repository.dart';

class GetBasicUserUseCase {
  final ProfileRepository _repository;
  const GetBasicUserUseCase(this._repository);

  Future<Either<Failure, BasicUser?>> call(String id) =>
      _repository.getBasicUser(id);
}
