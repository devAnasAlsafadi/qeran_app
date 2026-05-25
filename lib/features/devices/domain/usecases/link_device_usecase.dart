import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/device_repository.dart';

class LinkDeviceUseCase {
  final DeviceRepository _repository;

  const LinkDeviceUseCase(this._repository);

  Future<Either<Failure, Unit>> call({required String token}) =>
      _repository.linkDevice(token: token);
}
