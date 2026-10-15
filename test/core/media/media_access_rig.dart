import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/media/app_settings_opener.dart';

/// Counts how often the app's settings page was asked for.
class FakeSettingsOpener implements AppSettingsOpener {
  int opened = 0;

  @override
  Future<void> open() async => opened++;
}

/// Registers a [FakeSettingsOpener] in `sl`, as the app registers the real
/// one; call `sl.reset` in `tearDown`.
FakeSettingsOpener registerFakeSettingsOpener() {
  final opener = FakeSettingsOpener();
  sl.registerSingleton<AppSettingsOpener>(opener);
  return opener;
}
