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

  /// Server-authored text for [event], when the copy has to come from the
  /// backend rather than a local string.
  ///
  /// Only [ProfileReactionEvent.alreadyPending] uses it today, and it must:
  /// the server's duplicate-like check is BIDIRECTIONAL, firing both when you
  /// already liked them and when they already liked you. A local string can
  /// only describe one of those, so it is wrong half the time — the server
  /// message tells the two apart.
  final String? eventMessage;

  const ProfileReactionState({
    this.inFlight,
    this.event = ProfileReactionEvent.none,
    this.eventVersion = 0,
    this.eventMessage,
  });

  bool get isBusy => inFlight != null;
  bool get isLiking => inFlight == ProfileReactionAction.like;
  bool get isPassing => inFlight == ProfileReactionAction.pass;

  @override
  List<Object?> get props => [inFlight, event, eventVersion, eventMessage];
}
