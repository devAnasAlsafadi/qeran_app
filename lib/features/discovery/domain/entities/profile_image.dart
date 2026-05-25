import 'package:equatable/equatable.dart';

class ProfileImage extends Equatable {
  /// Image GUID assigned by the server.
  final String id;

  /// Absolute URL — already resolved against the server origin by the
  /// data layer. Never a relative path at the domain level.
  final String url;

  /// True for the primary profile image of the candidate. Exactly one
  /// per profile in normal operation; defensive code should still handle
  /// zero or multiple.
  final bool isProfile;

  /// True when the client must render a blur overlay on top of the image.
  /// The server does NOT ship pre-blurred bytes — see `DISCOVERY_PLAN.md`
  /// §10 R3.
  final bool isBlurred;

  const ProfileImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isBlurred];
}
