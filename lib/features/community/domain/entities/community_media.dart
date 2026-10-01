import 'package:equatable/equatable.dart';

/// One item of a post's media (contract §2.3). [width] and [height] are the
/// display size (after rotation for a video), so the feed can lay a frame out
/// before anything loads; 0 when the server sent none.
sealed class CommunityMedia extends Equatable {
  final int width;
  final int height;

  const CommunityMedia({required this.width, required this.height});
}

/// An image: [url] and [thumbnailUrl] are relative, Bearer-protected and
/// immutable on the server, so the device may cache them.
final class CommunityImage extends CommunityMedia {
  final String url;
  final String? thumbnailUrl;

  const CommunityImage({
    required this.url,
    this.thumbnailUrl,
    required super.width,
    required super.height,
  });

  @override
  List<Object?> get props => [url, thumbnailUrl, width, height];
}

/// A video. Every URL is absolute and signed — never sent with our Bearer.
/// [url] (a 720p MP4) is null while the video isn't ready, which only its
/// author ever sees. The signature lapses at [urlExpiresAt] (6 h), after
/// which the post has to be fetched again.
final class CommunityVideo extends CommunityMedia {
  final String? url;
  final String? posterUrl;
  final String? hlsUrl;
  final Duration duration;
  final DateTime? urlExpiresAt;

  const CommunityVideo({
    this.url,
    this.posterUrl,
    this.hlsUrl,
    required this.duration,
    this.urlExpiresAt,
    required super.width,
    required super.height,
  });

  @override
  List<Object?> get props =>
      [url, posterUrl, hlsUrl, duration, urlExpiresAt, width, height];
}

/// A post carries no media, 1–N images, or exactly one video (D11) — held in
/// the type, so no screen has to handle "images and a video".
sealed class CommunityPostMedia extends Equatable {
  const CommunityPostMedia();
}

final class CommunityNoMedia extends CommunityPostMedia {
  const CommunityNoMedia();

  @override
  List<Object?> get props => const [];
}

final class CommunityImageSet extends CommunityPostMedia {
  /// In the order the matchmaker arranged them. Never empty.
  final List<CommunityImage> images;

  const CommunityImageSet(this.images);

  @override
  List<Object?> get props => [images];
}

final class CommunitySingleVideo extends CommunityPostMedia {
  final CommunityVideo video;

  const CommunitySingleVideo(this.video);

  @override
  List<Object?> get props => [video];
}
