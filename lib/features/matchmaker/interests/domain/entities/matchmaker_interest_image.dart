import 'package:equatable/equatable.dart';

/// A profile image on an interests card (ProfileImageDto). [isBlurred] is the
/// backend's authoritative blur flag; [url] is absolute (the data layer runs it
/// through `EndPoints.absoluteUrl`).
class MatchmakerInterestImage extends Equatable {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const MatchmakerInterestImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isBlurred];
}
