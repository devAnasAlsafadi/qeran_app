import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository _repository;

  const LoginWithGoogleUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call() => _repository.loginWithGoogle();
}
