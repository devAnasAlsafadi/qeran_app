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

  const MatchImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isBlurred];
}
