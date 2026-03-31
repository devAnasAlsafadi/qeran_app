import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../repositories/auth_repository.dart';

class SendWhatsappOtpUseCase {
  final AuthRepository _repository;

  const SendWhatsappOtpUseCase(this._repository);

  Future<Either<Failure, Unit>> call({required String phoneNumber}) =>
      _repository.sendWhatsappOtp(phoneNumber: phoneNumber);
}
