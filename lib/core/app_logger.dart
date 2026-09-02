import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
  static const bool _isDebug = kDebugMode;

  static void info(String message, {String tag = 'INFO'}) {
    if (!_isDebug) return;
    dev.log('\x1B[32m$message\x1B[0m', name: tag, time: DateTime.now());
  }

  static void debug(String message, {String tag = 'DEBUG'}) {
    if (!_isDebug) return;
    dev.log('🔍 $message', name: tag);
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    if (!_isDebug) return;
    dev.log('⚠️ $message', name: tag);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    String tag = 'ERROR',
  }) {
    if (!_isDebug) return;
    dev.log('❌ $message', name: tag, error: error, stackTrace: stack);
  }

  /// Logs in RELEASE as well as debug. Everything else here is debug-only on
  /// purpose, so this is the deliberate exception, not a new default.
  ///
  /// ⚠️ Use it only where a failure would otherwise be UNDIAGNOSABLE in a
  /// shipped build, and only with text checked to carry no user data. A
  /// shipped app writes this to the device log, where anyone with the handset
  /// and a cable can read it — so pass error codes and types, never emails,
  /// tokens, names, or anything a user typed.
  ///
  /// [debugPrint] rather than [dev.log] for two reasons: it survives a release
  /// build, and tests can swap it out to assert what was written.
  static void releaseDiagnostic(String message, {String tag = 'DIAG'}) {
    debugPrint('[$tag] $message');
  }
}
