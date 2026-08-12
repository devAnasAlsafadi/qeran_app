import 'package:equatable/equatable.dart';

/// Authoritative one-time photo-view permission for one target user.
class PhotoViewPermission extends Equatable {
  final String targetUserId;
  final int? photoExchangeId;
  final bool isUnblurred;
  final DateTime? viewedAt;
  final DateTime? viewExpiresAt;
  final bool isConsumed;

  /// Optional forward-compatible field. The documented permission response
  /// does not require it, but when present it lets a restarted app safely
  /// resume the server countdown without trusting the device wall clock.
  final int? secondsRemaining;

  const PhotoViewPermission({
    required this.targetUserId,
    required this.photoExchangeId,
    required this.isUnblurred,
    required this.viewedAt,
    required this.viewExpiresAt,
    required this.isConsumed,
    this.secondsRemaining,
  });

  bool get hasAcceptedExchange => photoExchangeId != null;

  @override
  List<Object?> get props => [
    targetUserId,
    photoExchangeId,
    isUnblurred,
    viewedAt,
    viewExpiresAt,
    isConsumed,
    secondsRemaining,
  ];
}
