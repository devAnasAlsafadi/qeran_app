import 'package:equatable/equatable.dart';

/// The matchmaker's own profile image. [url] is absolute (the data layer runs
/// the server's relative path through `EndPoints.absoluteUrl`). The upload
/// endpoint also returns an `isApproved` flag, but a matchmaker's photo is
/// always approved, so it isn't modelled here.
class MatchmakerMeImage extends Equatable {
  final String id;
  final String url;
  final bool isProfile;

  const MatchmakerMeImage({
    required this.id,
    required this.url,
    required this.isProfile,
  });

  @override
  List<Object?> get props => [id, url, isProfile];
}
