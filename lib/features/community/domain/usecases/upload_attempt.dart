import 'dart:async';

import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/publish_event.dart';
import '../entities/publish_session.dart';
import '../repositories/community_author_repository.dart';

/// What one attempt's media uploads share (plan §3.4): progress per whole
/// percent, a failure or her cancel as the attempt's ending, and on her
/// cancel this session's uploads deleted, best effort (S6).
abstract class UploadAttempt {
  UploadAttempt(this.repository, this.session, this.cancel, this.emit);

  final CommunityAuthorRepository repository;
  final PublishSession session;
  final UploadCancel cancel;
  final PublishEmit emit;
  int _percent = -1;

  /// [sent] of [total] bytes are up.
  void progress(int sent, int total) {
    final percent = total == 0 ? 100 : sent * 100 ~/ total;
    if (percent == _percent) return;
    _percent = percent;
    emit(PublishUploading(percent / 100));
  }

  /// The attempt ends on [failure]: her cancel, or the failed strip (D3).
  T? stopped<T>(Failure failure) {
    failure is UploadCancelledFailure
        ? cancelled()
        : emit(PublishFailed(failure));
    return null;
  }

  /// Her cancel: what went up is deleted, best effort, and sent again from
  /// the start next time.
  void cancelled() {
    for (final id in session.uploadedIds) {
      unawaited(repository.deleteMedia(id));
    }
    session.forgetUploads();
    emit(const PublishCancelled());
  }
}
