import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import 'utils/log_masker.dart';

class AppLogger {
  static const bool _isDebug = kDebugMode;

  /// Where a debug line goes: `dev.log`. Tests swap it to read what was
  /// written. Every line, and any error passed with it, reaches it through
  /// [LogMasker.redact]: no token, email or phone number in a debug log
  /// (cleanup audit `19`, run 11).
  @visibleForTesting
  static void Function(
    String message,
    String tag,
    Object? error,
    StackTrace? stack,
  )
  sink = _toDevLog;

  static void _toDevLog(
    String message,
    String tag,
    Object? error,
    StackTrace? stack,
  ) => dev.log(message, name: tag, error: error, stackTrace: stack);

  static void _write(
    String message,
    String tag, {
    Object? error,
    StackTrace? stack,
  }) => sink(
    LogMasker.redact(message),
    tag,
    error == null ? null : LogMasker.redact('$error'),
    stack,
  );

  static void info(String message, {String tag = 'INFO'}) {
    if (!_isDebug) return;
    _write('\x1B[32m$message\x1B[0m', tag);
  }

  static void debug(String message, {String tag = 'DEBUG'}) {
    if (!_isDebug) return;
    _write('🔍 $message', tag);
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    if (!_isDebug) return;
    _write('⚠️ $message', tag);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    String tag = 'ERROR',
  }) {
    if (!_isDebug) return;
    _write('❌ $message', tag, error: error, stack: stack);
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
