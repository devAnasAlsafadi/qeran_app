import 'package:equatable/equatable.dart';

/// Sealed image payload — the owner shape is my own photo, the other shape
/// carries `isBlurred` (peer-visibility gate). `url` is always absolute
/// (resolved against the API origin at the data layer).
sealed class ProfileImage extends Equatable {
  String get id;
  String get url;
  bool get isProfile;

  const ProfileImage();
}

final class OwnerImage extends ProfileImage {
  @override
  final String id;
  @override
  final String url;
  @override
  final bool isProfile;

  const OwnerImage({
    required this.id,
    required this.url,
    required this.isProfile,
  });

  @override
  List<Object?> get props => [id, url, isProfile];
}

final class OtherProfileImage extends ProfileImage {
  @override
  final String id;
  @override
  final String url;
  @override
  final bool isProfile;

  /// True until both users complete a photo exchange.
  final bool isBlurred;

  /// Server-rendered blurred renditions. Preferred over a client filter
  /// while the photo is shown blurred — the detail is already gone from
  /// those bytes. Null falls back to the client filter.
  final String? blurredUrl;
  final String? blurredThumbnailUrl;

  const OtherProfileImage({
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
