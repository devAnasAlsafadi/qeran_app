import 'package:equatable/equatable.dart';

import 'formal_request.dart';
import 'match_image.dart';
import 'match_stage.dart';
import 'photo_exchange_pending.dart';

/// One row in the Matches tab.
///
/// Stage drives the UI variant; `pendingPhotoExchange`, `formalRequest`
/// and `conversationId` are stage-specific adornments. `images` is the
/// full ordered gallery (server pre-sorts, profile-first) — the card
/// renders the first entry and the gallery sheet renders the full list.
class MatchCard extends Equatable {
  final int likeRequestId;
  final String otherUserId;
  final String otherUserName;
  final List<MatchImage> images;
  final MatchStage stage;
  final PhotoExchangePending? pendingPhotoExchange;
  final FormalRequest? formalRequest;
  final String? conversationId;

  const MatchCard({
    required this.likeRequestId,
    required this.otherUserId,
    required this.otherUserName,
    required this.images,
    required this.stage,
    required this.pendingPhotoExchange,
    required this.formalRequest,
    required this.conversationId,
  });

  /// First profile image if any, else the first image, else null.
  MatchImage? get primaryImage {
    if (images.isEmpty) return null;
    for (final img in images) {
      if (img.isProfile) return img;
    }
    return images.first;
  }

  @override
  List<Object?> get props => [
        likeRequestId,
        otherUserId,
        otherUserName,
        images,
        stage,
        pendingPhotoExchange,
        formalRequest,
        conversationId,
      ];
}
