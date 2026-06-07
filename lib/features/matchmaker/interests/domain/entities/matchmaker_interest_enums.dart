/// Read-only interest enums for the matchmaker mirror. Own copies (not the
/// likes feature's) so the interests domain stays decoupled; parsed defensively
/// from either enum-name strings or legacy numeric codes.
library;

/// Which like list to fetch.
enum MatchmakerLikeDirection { outgoing, incoming }

/// The lifecycle of a like request, mirrored read-only.
enum MatchmakerInterestLikeStatus {
  pending,
  accepted,
  rejected,
  expired,
  unknown,
}

MatchmakerInterestLikeStatus matchmakerLikeStatusFromWire(Object? raw) {
  if (raw is num) {
    return switch (raw.toInt()) {
      0 => MatchmakerInterestLikeStatus.pending,
      1 => MatchmakerInterestLikeStatus.accepted,
      2 => MatchmakerInterestLikeStatus.rejected,
      3 => MatchmakerInterestLikeStatus.expired,
      _ => MatchmakerInterestLikeStatus.unknown,
    };
  }
  return switch (raw?.toString().toLowerCase().trim()) {
    'pending' => MatchmakerInterestLikeStatus.pending,
    'accepted' => MatchmakerInterestLikeStatus.accepted,
    'rejected' => MatchmakerInterestLikeStatus.rejected,
    'expired' => MatchmakerInterestLikeStatus.expired,
    _ => MatchmakerInterestLikeStatus.unknown,
  };
}

/// The stage of an active match, mirrored read-only.
enum MatchmakerInterestMatchStage {
  waitingForPhotoExchange,
  photosExchanged,
  matchmakerEngaged,
  unknown,
}

MatchmakerInterestMatchStage matchmakerMatchStageFromWire(Object? raw) {
  if (raw is num) {
    return switch (raw.toInt()) {
      0 => MatchmakerInterestMatchStage.waitingForPhotoExchange,
      1 => MatchmakerInterestMatchStage.photosExchanged,
      2 => MatchmakerInterestMatchStage.matchmakerEngaged,
      _ => MatchmakerInterestMatchStage.unknown,
    };
  }
  return switch (raw?.toString().toLowerCase().trim()) {
    'waitingforphotoexchange' =>
      MatchmakerInterestMatchStage.waitingForPhotoExchange,
    'photosexchanged' => MatchmakerInterestMatchStage.photosExchanged,
    'matchmakerengaged' => MatchmakerInterestMatchStage.matchmakerEngaged,
    _ => MatchmakerInterestMatchStage.unknown,
  };
}

/// Which kind of archived item — distinguishes a closed like from a closed
/// photo-exchange (ArchiveItemDto.type).
enum MatchmakerArchiveType { like, photoExchange, unknown }

MatchmakerArchiveType matchmakerArchiveTypeFromWire(Object? raw) {
  return switch (raw?.toString().toLowerCase().trim()) {
    'like' => MatchmakerArchiveType.like,
    'photo_exchange' || 'photoexchange' => MatchmakerArchiveType.photoExchange,
    _ => MatchmakerArchiveType.unknown,
  };
}

/// Why an item was archived (ArchiveItemDto.reason) — drives the status chip
/// colour and a fallback label when no `status` text is provided.
enum MatchmakerArchiveReason { rejected, expired, unknown }

MatchmakerArchiveReason matchmakerArchiveReasonFromWire(Object? raw) {
  return switch (raw?.toString().toLowerCase().trim()) {
    'rejected' => MatchmakerArchiveReason.rejected,
    'expired' => MatchmakerArchiveReason.expired,
    _ => MatchmakerArchiveReason.unknown,
  };
}
