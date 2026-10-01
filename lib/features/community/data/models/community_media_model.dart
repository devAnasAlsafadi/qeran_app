import '../../domain/entities/community_media.dart';
import '../json_parsers.dart';

/// Wire model for one Media item (contract §2.3): an `Image`
/// `{ type, url, thumbnailUrl, width, height }` or a `Video`
/// `{ type, url, posterUrl, hlsUrl, width, height, durationSeconds,
/// urlExpiresAt }`.
class CommunityMediaModel {
  final String type;
  final String? url;
  final String? thumbnailUrl;
  final String? posterUrl;
  final String? hlsUrl;
  final int width;
  final int height;
  final int durationSeconds;
  final DateTime? urlExpiresAt;

  const CommunityMediaModel({
    required this.type,
    required this.url,
    required this.thumbnailUrl,
    required this.posterUrl,
    required this.hlsUrl,
    required this.width,
    required this.height,
    required this.durationSeconds,
    required this.urlExpiresAt,
  });

  factory CommunityMediaModel.fromJson(Map<String, dynamic> json) =>
      CommunityMediaModel(
        type: parseString(json['type']).toLowerCase(),
        url: _url(json['url']),
        thumbnailUrl: _url(json['thumbnailUrl']),
        posterUrl: _url(json['posterUrl']),
        hlsUrl: _url(json['hlsUrl']),
        width: parseInt(json['width']),
        height: parseInt(json['height']),
        durationSeconds: parseInt(json['durationSeconds']),
        urlExpiresAt: parseNullableDateTime(json['urlExpiresAt']),
      );

  /// Null for a type this build doesn't know, and for an image without a
  /// URL — neither can be drawn.
  CommunityMedia? toEntity() => switch (type) {
        'image' when url != null => CommunityImage(
            url: url!,
            thumbnailUrl: thumbnailUrl,
            width: width,
            height: height,
          ),
        'video' => CommunityVideo(
            url: url,
            posterUrl: posterUrl,
            hlsUrl: hlsUrl,
            duration: Duration(seconds: durationSeconds),
            urlExpiresAt: urlExpiresAt,
            width: width,
            height: height,
          ),
        _ => null,
      };

  /// A post's media list as the one shape D11 allows. The server never mixes
  /// images and a video; if it ever did, the video wins (one item, nothing
  /// half-drawn) rather than a set the UI has no frame for.
  static CommunityPostMedia postMediaFrom(List<CommunityMediaModel> models) {
    final items = models.map((m) => m.toEntity()).whereType<CommunityMedia>();
    final videos = items.whereType<CommunityVideo>();
    if (videos.isNotEmpty) return CommunitySingleVideo(videos.first);
    final images = items.whereType<CommunityImage>().toList(growable: false);
    if (images.isNotEmpty) return CommunityImageSet(images);
    return const CommunityNoMedia();
  }

  static String? _url(Object? raw) {
    final value = parseNullableString(raw)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }
}
