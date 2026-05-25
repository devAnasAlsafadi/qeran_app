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
}
