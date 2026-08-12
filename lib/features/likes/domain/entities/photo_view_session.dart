import 'package:equatable/equatable.dart';

/// Result of starting (or idempotently re-reading) a photo-view window.
class PhotoViewSession extends Equatable {
  final int photoExchangeId;
  final DateTime viewedAt;
  final DateTime viewExpiresAt;
  final int secondsRemaining;

  const PhotoViewSession({
    required this.photoExchangeId,
    required this.viewedAt,
    required this.viewExpiresAt,
    required this.secondsRemaining,
  });

  @override
  List<Object?> get props => [
    photoExchangeId,
    viewedAt,
    viewExpiresAt,
    secondsRemaining,
  ];
}
