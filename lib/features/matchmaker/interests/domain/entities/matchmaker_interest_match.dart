import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/matchmaker_card_answer.dart';
import 'matchmaker_interest_enums.dart';
import 'matchmaker_interest_formal_request.dart';
import 'matchmaker_interest_image.dart';
import 'matchmaker_interest_photo_exchange.dart';

/// One active match in the read-only matchmaker mirror — the OTHER party, their
/// images (blur per [MatchmakerInterestImage.isBlurred]), the [stage], and the
/// matchmaker's flagged answers. Photo-exchange / formal-step actions are
/// dropped (view-only).
class MatchmakerInterestMatch extends Equatable {
  final String otherUserId;
  final String name;
  final List<MatchmakerInterestImage> images;
  final MatchmakerInterestMatchStage stage;
  final bool isLocked;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  /// Backend-provided formal-request progress; `null` before any formal step.
  final MatchmakerInterestFormalRequest? formalRequest;

  /// The in-flight photo-exchange window, when one exists. Read-only here —
  /// it drives the countdown chip, never an action.
  final MatchmakerInterestPhotoExchange? pendingPhotoExchange;

  const MatchmakerInterestMatch({
    required this.otherUserId,
    required this.name,
    this.images = const [],
    required this.stage,
    this.isLocked = false,
    this.age,
    this.answers = const [],
    this.formalRequest,
    this.pendingPhotoExchange,
  });

  /// Profile image first, else the first image, else null.
  MatchmakerInterestImage? get primaryImage {
    for (final i in images) {
      if (i.isProfile) return i;
    }
    return images.isEmpty ? null : images.first;
  }

  @override
  List<Object?> get props => [
    otherUserId,
    name,
    images,
    stage,
    isLocked,
    age,
    answers,
    formalRequest,
    pendingPhotoExchange,
  ];
}
