import 'package:equatable/equatable.dart';

/// One image attached to a shared profile. URL is the absolute
/// authenticated URL (resolved at the model→entity boundary).
class SharedProfileImage extends Equatable {
  final String id;
  final String url;
  final bool isProfile;
  final bool isBlurred;

  const SharedProfileImage({
    required this.id,
    required this.url,
    required this.isProfile,
    required this.isBlurred,
  });

  @override
  List<Object?> get props => [id, url, isProfile, isBlurred];
}
