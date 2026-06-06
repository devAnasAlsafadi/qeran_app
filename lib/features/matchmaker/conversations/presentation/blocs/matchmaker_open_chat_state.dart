import 'package:equatable/equatable.dart';

/// One-shot outcome the host listens to: navigate on [ready], snackbar on
/// [failure]. The host reacts on every [MatchmakerOpenChatState.eventVersion]
/// bump and ignores [none], so a side effect never fires twice for one tap.
enum MatchmakerOpenChatOutcome { none, ready, failure }

/// State for [MatchmakerOpenChatCubit]. Each emit is a fresh value (no
/// copyWith) so a previous tap's navigation payload never leaks into the next
/// — only [eventVersion] carries across to keep the one-shot signal monotonic.
class MatchmakerOpenChatState extends Equatable {
  /// The user whose chat is currently resolving, or `null` when idle — drives
  /// the inline loader on that card's مراسلة button.
  final String? openingUserId;

  final MatchmakerOpenChatOutcome outcome;
  final int eventVersion;

  /// Navigation payload, set together with [MatchmakerOpenChatOutcome.ready].
  final int? conversationId;
  final String? peerUserId;
  final String? peerName;
  final String? peerImageUrl;

  /// Error text for a [MatchmakerOpenChatOutcome.failure] (locale key or ready
  /// Arabic) — run through `.t(context)` in the UI.
  final String? errorMessage;

  const MatchmakerOpenChatState({
    this.openingUserId,
    this.outcome = MatchmakerOpenChatOutcome.none,
    this.eventVersion = 0,
    this.conversationId,
    this.peerUserId,
    this.peerName,
    this.peerImageUrl,
    this.errorMessage,
  });

  bool get isOpening => openingUserId != null;

  @override
  List<Object?> get props => [
        openingUserId,
        outcome,
        eventVersion,
        conversationId,
        peerUserId,
        peerName,
        peerImageUrl,
        errorMessage,
      ];
}
