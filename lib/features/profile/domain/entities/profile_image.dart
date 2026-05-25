import 'package:equatable/equatable.dart';

/// Sealed image payload — owner shape carries `isApproved` (matchmaker
/// review gate on my own photos), other shape carries `isBlurred`
/// (peer-visibility gate). `url` is always absolute (resolved against
/// the API origin at the data layer).
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

  /// True when the matchmaker has approved the image. False images are
  /// shown to the owner (their gallery) but hidden from peers.
  final bool isApproved;

  const OwnerImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isApproved,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isApproved];
}

final class OtherProfileImage extends ProfileImage {
  @override
  final String id;
  @override
  final String url;
  @override
  final bool isProfile;

  /// True until both users complete a photo exchange. Blur is enforced
  /// in the UI; backend ships the cleartext URL regardless.
  final bool isBlurred;

  const OtherProfileImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isBlurred];
}
