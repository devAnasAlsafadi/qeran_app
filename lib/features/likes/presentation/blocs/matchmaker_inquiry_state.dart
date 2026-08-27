import 'package:equatable/equatable.dart';

/// One-shot outcome of the most recent inquiry, rendered by the screen as a
/// snackbar.
///
/// Its own enum rather than a slice of `LikesActionEvent`. A shared enum would
/// leave this cubit's listener switch answering thirty-odd events it can never
/// emit, and the exhaustiveness that makes an unhandled event a COMPILE error
/// is only useful while every arm is one this cubit can actually reach.
enum InquiryEvent { none, success, alreadySent, failure }

/// State of the stage-0 matchmaker inquiry: which cards have one in flight,
/// which have already had one this session, and the last outcome.
///
/// [sentLikeIds] is session-scoped ON PURPOSE and always has been — the server
/// exposes no "has this member already asked about this match" flag, so the
/// alternative is not a durable answer but a fabricated one. It resets on
/// restart and the member may ask again, which is the honest behaviour.
class MatchmakerInquiryState extends Equatable {
  const MatchmakerInquiryState({
    this.inFlightLikeIds = const <int>{},
    this.sentLikeIds = const <int>{},
    this.event = InquiryEvent.none,
    this.eventVersion = 0,
  });

  /// LIKE-REQUEST ids whose inquiry share/message is in-flight.
  final Set<int> inFlightLikeIds;

  /// LIKE-REQUEST ids whose inquiry was sent this session.
  final Set<int> sentLikeIds;

  /// The screen reacts on every [eventVersion] bump and ignores
  /// [InquiryEvent.none].
  final InquiryEvent event;
  final int eventVersion;

  bool isSending(int likeRequestId) => inFlightLikeIds.contains(likeRequestId);

  bool isSent(int likeRequestId) => sentLikeIds.contains(likeRequestId);

  MatchmakerInquiryState copyWith({
    Set<int>? inFlightLikeIds,
    Set<int>? sentLikeIds,
    InquiryEvent? event,
    int? eventVersion,
  }) {
    return MatchmakerInquiryState(
      inFlightLikeIds: inFlightLikeIds ?? this.inFlightLikeIds,
      sentLikeIds: sentLikeIds ?? this.sentLikeIds,
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props => [
    inFlightLikeIds,
    sentLikeIds,
    event,
    eventVersion,
  ];
}
