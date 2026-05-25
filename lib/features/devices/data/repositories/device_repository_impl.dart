import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/repositories/device_repository.dart';
import '../datasources/device_remote_datasource.dart';
import '../models/link_device_request_model.dart';
import '../models/register_device_request_model.dart';

class DeviceRepositoryImpl with BaseRepository implements DeviceRepository {
  final DeviceRemoteDataSource _dataSource;

  const DeviceRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Unit>> registerDevice({
    required String token,
    required int deviceType,
    required String language,
    String? deviceName,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  }) {
    return executeApiCall(() async {
      await _dataSource.registerDevice(
        RegisterDeviceRequestModel(
          token: token,
          deviceType: deviceType,
          language: language,
          deviceName: deviceName,
          deviceModel: deviceModel,
          osVersion: osVersion,
          appVersion: appVersion,
        ),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> linkDevice({required String token}) {
    return executeApiCall(() async {
      await _dataSource.linkDevice(LinkDeviceRequestModel(token: token));
      return unit;
    });
  }
}
