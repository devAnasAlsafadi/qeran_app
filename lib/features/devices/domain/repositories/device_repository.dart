import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

abstract interface class DeviceRepository {
  /// Public endpoint — registers (or upserts) the device with the FCM token
  /// and the optional metadata. No JWT required.
  Future<Either<Failure, Unit>> registerDevice({
    required String token,
    required int deviceType,
    required String language,
    String? deviceName,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  });

  /// Protected — links the registered device to the currently authenticated
  /// user. Bearer is attached automatically by `HttpConsumer` from
  /// `StorageKeys.token`.
  Future<Either<Failure, Unit>> linkDevice({required String token});
}
