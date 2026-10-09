import 'dart:async';

import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/services/storage_service.dart';

/// A purchase the store confirmed that the server hasn't confirmed yet (C5).
///
/// Kept on the phone with the moment it began, so closing the app never turns
/// "activating" into Free (Q26). It's an account-level pref: a sign-out, a
/// delete and a session-less start remove it with the rest
/// ([StorageKeys.accountKeys]). Settled by the first `/current` showing an
/// active subscription. No time limit: after [overdueAfter] the surfaces add a
/// line pointing to Help & support.
class ActivationPending {
  ActivationPending({
    required StorageService prefs,
    DateTime Function()? now,
    List<Duration> reReads = defaultReReads,
  }) : _prefs = prefs,
       _now = now ?? DateTime.now,
       _reReads = reReads;

  final StorageService _prefs;
  final DateTime Function() _now;
  final List<Duration> _reReads;

  /// About two minutes of re-reads after the store confirms (Q26); after
  /// that, every resume and pull to refresh re-reads.
  static const List<Duration> defaultReReads = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 15),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 30),
  ];

  /// How long "activating" waits before suggesting Help & support.
  static const Duration overdueAfter = Duration(minutes: 10);

  static const String _key = StorageKeys.subscriptionActivationSince;

  DateTime? _since;
  bool _loaded = false;
  bool _watching = false;
  Timer? _overdueTimer;

  /// When the store confirmed it; null when nothing is activating.
  DateTime? get since => _since;

  bool get isPending => _since != null;

  bool get isOverdue {
    final since = _since;
    return since != null && !_now().isBefore(since.add(overdueAfter));
  }

  /// Reads the kept marker, once per account.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final ms = await _prefs.get<int>(_key);
    if (ms != null) _since ??= DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// The store confirmed a purchase. One still activating keeps its start.
  Future<void> start() async {
    final since = _since ??= _now();
    await _prefs.save<int>(_key, since.millisecondsSinceEpoch);
  }

  /// The server confirmed it.
  Future<void> settle() async {
    _stop();
    await _prefs.remove(_key);
  }

  /// Calls [reRead] now and then on [_reReads], while still activating and
  /// [alive]. One loop at a time.
  Future<void> watch(
    Future<void> Function() reRead, {
    required bool Function() alive,
  }) async {
    if (_watching) return;
    _watching = true;
    bool waiting() => alive() && isPending;
    try {
      await reRead();
      for (final delay in _reReads) {
        if (!waiting()) return;
        await Future<void>.delayed(delay);
        if (!waiting()) return;
        await reRead();
      }
    } finally {
      _watching = false;
    }
  }

  /// Calls [onOverdue] once, at the overdue moment, if still activating then.
  void whenOverdue(void Function() onOverdue) {
    final since = _since;
    if (since == null || isOverdue || _overdueTimer != null) return;
    _overdueTimer = Timer(since.add(overdueAfter).difference(_now()), () {
      _overdueTimer = null;
      if (isPending) onOverdue();
    });
  }

  /// The account changed (its prefs go with it), or the holder closed.
  void forgetAccount() {
    _stop();
    _loaded = false;
  }

  void _stop() {
    _overdueTimer?.cancel();
    _overdueTimer = null;
    _since = null;
  }
}
