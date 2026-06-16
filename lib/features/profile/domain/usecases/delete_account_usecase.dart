import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/profile_repository.dart';

/// Permanently deletes the signed-in user's account (`DELETE /api/Profile`).
/// Irreversible: cancels any active subscription (no refund) and removes the
/// user's chats/likes/archive from everyone's side. The post-success cleanup
/// (device unlink → local wipe → redirect to login) is orchestrated above.
class DeleteAccountUseCase {
  final ProfileRepository _repository;

  const DeleteAccountUseCase(this._repository);

  Future<Either<Failure, Unit>> call() => _repository.deleteAccount();
}
