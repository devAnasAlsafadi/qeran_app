import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUserUseCase {
  final AuthRepository _repository;

  const RegisterUserUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String email,
    required String password,
  }) => _repository.registerUser(name: name, email: email, password: password);
}
