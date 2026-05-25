import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/device_repository.dart';

class RegisterDeviceUseCase {
  final DeviceRepository _repository;

  const RegisterDeviceUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String token,
    required int deviceType,
    required String language,
    String? deviceName,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  }) => _repository.registerDevice(
    token: token,
    deviceType: deviceType,
    language: language,
    deviceName: deviceName,
    deviceModel: deviceModel,
    osVersion: osVersion,
    appVersion: appVersion,
  );
}
