import 'package:qeran/core/errors/errors.dart';

import 'media_refusal.dart';
import 'post_publish_outcome.dart';

/// What one publish attempt reports, in order (plan §3.4): progress while
/// her video is prepared and her media goes up, then exactly one ending.
sealed class PublishEvent {
  const PublishEvent();
}

/// Where a publish attempt reports its events.
typedef PublishEmit = void Function(PublishEvent event);

/// Her video being made ready on the phone (D1): [progress] from 0 to 1.
final class PublishCompressing extends PublishEvent {
  final double progress;
  const PublishCompressing(this.progress);
}

/// Her media going up: [progress] from 0 to 1, by bytes across all of it.
final class PublishUploading extends PublishEvent {
  final double progress;
  const PublishUploading(this.progress);
}

/// Her media is up and the post is being made: too late to cancel.
final class PublishCreating extends PublishEvent {
  const PublishCreating();
}

/// The server's answer to 6.2 (or to 6.8 for the video), as an outcome.
final class PublishAnswered extends PublishEvent {
  final PostPublishOutcome outcome;
  const PublishAnswered(this.outcome);
}

/// The server's own check refused one image (6.7): it leaves the draft.
final class PublishImageRefused extends PublishEvent {
  final String path;
  final MediaRefusal refusal;
  const PublishImageRefused({required this.path, required this.refusal});
}

/// Her video can't go up as it is (Q3): it leaves the draft. [sizeBytes]
/// is the file that would have gone up, compressed or not.
final class PublishVideoRefused extends PublishEvent {
  final String path;
  final MediaRefusal refusal;
  final int sizeBytes;
  const PublishVideoRefused({
    required this.path,
    required this.refusal,
    required this.sizeBytes,
  });
}

/// It didn't get through (D3): Retry goes on from where it stopped.
final class PublishFailed extends PublishEvent {
  final Failure failure;
  const PublishFailed(this.failure);
}

/// She cancelled: the draft is hers to edit again (D2).
final class PublishCancelled extends PublishEvent {
  const PublishCancelled();
}
