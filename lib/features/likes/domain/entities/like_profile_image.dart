import 'package:equatable/equatable.dart';

/// Avatar payload attached to a [LikeRequestCard]. Same shape as the
/// Discovery profile image but kept local so the Likes feature doesn't
/// reach across feature boundaries for a domain type.
///
/// [url] is **already absolute** — the data layer resolves the
/// server-supplied relative path via `EndPoints.absoluteUrl` before
/// constructing this entity.
class LikeProfileImage extends Equatable {
  final String id;
  final String url;
  final bool isProfile;

  /// True until the two users exchange photos.
  final bool isBlurred;

  /// Server-rendered blurred rendition, when the backend supplies one. This
  /// is the preferred source while [isBlurred] holds — the detail is already
  /// gone from the bytes, so nothing recoverable reaches the device. Null
  /// falls the UI back to a client-side filter over [url].
  final String? blurredUrl;

  /// Smaller variant of [blurredUrl] for compact surfaces like list avatars.
  final String? blurredThumbnailUrl;

  const LikeProfileImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
    this.blurredUrl,
    this.blurredThumbnailUrl,
  });

  @override
  List<Object?> get props => [
        id,
        url,
        isProfile,
        isBlurred,
        blurredUrl,
        blurredThumbnailUrl,
      ];
}
