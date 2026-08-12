import 'package:equatable/equatable.dart';

enum ProfileReactionAction { like, pass }

enum ProfileReactionEvent {
  none,
  likeSuccess,
  passSuccess,
  paywall,
  alreadyPending,
  genderMismatch,
  userUnavailable,
  underReview,
  failure,
}

class ProfileReactionState extends Equatable {
  final ProfileReactionAction? inFlight;
  final ProfileReactionEvent event;
  final int eventVersion;

  const ProfileReactionState({
    this.inFlight,
    this.event = ProfileReactionEvent.none,
    this.eventVersion = 0,
  });

  bool get isBusy => inFlight != null;
  bool get isLiking => inFlight == ProfileReactionAction.like;
  bool get isPassing => inFlight == ProfileReactionAction.pass;

  @override
  List<Object?> get props => [inFlight, event, eventVersion];
}
