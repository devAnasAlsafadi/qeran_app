import 'package:equatable/equatable.dart';

/// One image attached to a match. The list arrives server-sorted with
/// `isProfile == true` first; deleted images are pre-filtered. URL is
/// the absolute server URL (model layer resolves it via
/// `EndPoints.absoluteUrl`).
class MatchImage extends Equatable {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  /// Server-rendered blurred rendition. Safe to fetch even while the one-time
  /// view policy is refusing the original, because the detail is already gone
  /// from these bytes. Null falls back to a client-side filter.
  final String? blurredUrl;

  /// Smaller variant of [blurredUrl] for compact surfaces.
  final String? blurredThumbnailUrl;

  const MatchImage({
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
