import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/device_repository.dart';

/// Unlinks this device's FCM token from the user (stop push). Best-effort,
/// used during account deletion.
class UnlinkDeviceUseCase {
  final DeviceRepository _repository;

  const UnlinkDeviceUseCase(this._repository);

  Future<Either<Failure, Unit>> call({required String token}) =>
      _repository.unlinkDevice(token: token);
}
