import 'dart:async';

import 'package:qeran/features/community/domain/entities/community_post.dart';

import '../../../../shared/domain/entities/community_post_status_change.dart';

/// Starts a repeating timer; `Timer.periodic` in the app, a hand-driven one
/// in tests.
typedef PeriodicTimerStarter =
    Timer Function(Duration every, void Function(Timer timer) tick);

/// Keeps her posts still processing in view until the server says they're
/// done (plan §3.5, Q6): the hub's `CommunityPostStatusChanged`, and —
/// since that event has never been seen live — a read every [every] while
/// one is on her list. Either way the post is read again ([reread]); the
/// repository hands the fresh copy to every list and screen showing it.
/// Nothing promises a time: processing has taken about 5 minutes for 15 s.
class ProcessingWatch {
  ProcessingWatch({
    required Stream<CommunityPostStatusChange> statusChanges,
    required Future<void> Function(int postId) reread,
    this.every = const Duration(seconds: 15),
    PeriodicTimerStarter startTimer = Timer.periodic,
  }) : _reread = reread,
       _startTimer = startTimer {
    _changes = statusChanges.listen(_onChange);
  }

  final Duration every;
  final Future<void> Function(int postId) _reread;
  final PeriodicTimerStarter _startTimer;
  late final StreamSubscription<CommunityPostStatusChange> _changes;

  Set<int> _watching = const {};
  Timer? _timer;

  /// The posts on her list right now: the processing ones are watched, the
  /// rest let go. The timer runs only while there's one to watch.
  void follow(Iterable<CommunityPost> posts) {
    _watching = {
      for (final post in posts)
        if (post.status == CommunityPostStatus.processing) post.id,
    };
    if (_watching.isEmpty) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= _startTimer(every, (_) => checkNow());
    }
  }

  /// Reads every watched post again — each tick, and when the app comes back.
  void checkNow() {
    for (final postId in _watching.toList()) {
      unawaited(_reread(postId));
    }
  }

  void _onChange(CommunityPostStatusChange change) {
    if (_watching.contains(change.postId)) unawaited(_reread(change.postId));
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _changes.cancel();
  }
}
