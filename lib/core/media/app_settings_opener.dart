import 'package:app_settings/app_settings.dart';

/// Opens the app's own page in the phone's settings, the only way back to
/// the camera or the photos once they were refused (iOS never asks twice).
/// Registered in `sl`, so tests can tell whether it was opened.
class AppSettingsOpener {
  const AppSettingsOpener();

  Future<void> open() => AppSettings.openAppSettings();
}
