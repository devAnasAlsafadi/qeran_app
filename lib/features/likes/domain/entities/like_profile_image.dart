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

  /// True until the two users exchange photos. The UI applies the blur
  /// on the client side; the bytes themselves are never pre-processed.
  final bool isBlurred;

  const LikeProfileImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isBlurred];
}
