import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_logger.dart';

/// Snapshot of the running device used to enrich /Devices/register.
/// All fields except [deviceType] are best-effort; the API doc marks them
/// optional.
class DeviceMetadata {
  final int deviceType; // 0=Android, 1=iOS, 2=Web
  final String? deviceName;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;

  const DeviceMetadata({
    required this.deviceType,
    this.deviceName,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
  });
}

/// Resolves device metadata for the Devices/register payload.
class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo;

  DeviceInfoService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<DeviceMetadata> resolve() async {
    final type = _resolveDeviceType();
    String? appVersion;
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVersion = pkg.version;
    } catch (e) {
      AppLogger.warning('PackageInfo failed: $e', tag: 'DEVICE_INFO');
    }

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return DeviceMetadata(
          deviceType: type,
          deviceName: info.device,
          deviceModel: info.model,
          osVersion: 'Android ${info.version.release}',
          appVersion: appVersion,
        );
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return DeviceMetadata(
          deviceType: type,
          deviceName: info.name,
          deviceModel: info.utsname.machine,
          osVersion: '${info.systemName} ${info.systemVersion}',
          appVersion: appVersion,
        );
      }
    } catch (e, s) {
      AppLogger.error(
        'DeviceInfo resolve failed',
        error: e,
        stack: s,
        tag: 'DEVICE_INFO',
      );
    }
    return DeviceMetadata(deviceType: type, appVersion: appVersion);
  }

  int _resolveDeviceType() {
    if (Platform.isAndroid) return 0;
    if (Platform.isIOS) return 1;
    return 2;
  }
}
