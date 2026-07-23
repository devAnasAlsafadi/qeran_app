import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../app_logger.dart';

/// Starts Firebase after the first Flutter frame while exposing a shared
/// readiness gate to features that cannot safely run before initialization.
class FirebaseInitializationService {
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void>? _initialization;

  /// Completes after initialization succeeds or degrades safely on failure.
  /// Reading this future never starts native work during a widget build.
  Future<void> get ready => _readyCompleter.future;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.debug('✅ Firebase Connected Successfully!');
    } catch (e, stack) {
      AppLogger.error(
        '❌ Firebase Connection Failed',
        error: e,
        stack: stack,
        tag: 'FIREBASE',
      );
    } finally {
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }
}
