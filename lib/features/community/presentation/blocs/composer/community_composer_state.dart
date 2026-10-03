import 'package:equatable/equatable.dart';

import '../../../domain/entities/community_comment.dart';

/// One-shot messages for the composer, told apart by
/// [CommunityComposerState.eventVersion]. All but [focus] come with the
/// text given back ([CommunityComposerState.restore]).
enum CommunityComposerEvent {
  none,

  /// Reply was tapped: the field takes the focus (D2).
  focus,

  /// The filter refused it (D8) — the banner says why.
  filtered,

  /// Too many in a short time (D9): the send button rests a while.
  rateLimited,

  /// The member can't take part yet (read-only, decision D9).
  notApproved,

  /// The comment it answered is gone (S9).
  contentGone,

  /// The display name is still the default: the name step runs first.
  openNameGate,

  /// The guidelines aren't accepted yet: they run first.
  openGuidelines,
}

class CommunityComposerState extends Equatable {
  /// The comment being answered; null while writing a comment (D2).
  final CommunityComment? replyTo;

  /// The server's comment limit (config); null leaves it to the server.
  final int? maxLength;

  /// The last send was refused by the filter (D8).
  final bool filtered;

  /// Sending rests until then (D9).
  final DateTime? cooldownUntil;

  /// Text to give back to the field — if the member hasn't started another.
  final String? restore;
  final CommunityComposerEvent event;
  final int eventVersion;

  const CommunityComposerState({
    this.replyTo,
    this.maxLength,
    this.filtered = false,
    this.cooldownUntil,
    this.restore,
    this.event = CommunityComposerEvent.none,
    this.eventVersion = 0,
  });

  bool get coolingDown => cooldownUntil != null;

  /// Where the counter starts showing: 80 % of the limit (S3).
  int? get counterFrom => switch (maxLength) {
    final max? => (max * 0.8).ceil(),
    null => null,
  };

  /// Whether [text], trimmed, runs past the limit (D4).
  bool tooLong(String text) => switch (maxLength) {
    final max? => text.trim().length > max,
    null => false,
  };

  CommunityComposerState copyWith({
    CommunityComment? Function()? replyTo,
    int? maxLength,
    bool? filtered,
    DateTime? Function()? cooldownUntil,
    String? Function()? restore,
  }) => CommunityComposerState(
    replyTo: replyTo == null ? this.replyTo : replyTo(),
    maxLength: maxLength ?? this.maxLength,
    filtered: filtered ?? this.filtered,
    cooldownUntil: cooldownUntil == null ? this.cooldownUntil : cooldownUntil(),
    restore: restore == null ? this.restore : restore(),
    event: event,
    eventVersion: eventVersion,
  );

  /// This state, telling the composer [next] once.
  CommunityComposerState withEvent(CommunityComposerEvent next) =>
      CommunityComposerState(
        replyTo: replyTo,
        maxLength: maxLength,
        filtered: filtered,
        cooldownUntil: cooldownUntil,
        restore: restore,
        event: next,
        eventVersion: eventVersion + 1,
      );

  @override
  List<Object?> get props => [
    replyTo,
    maxLength,
    filtered,
    cooldownUntil,
    restore,
    event,
    eventVersion,
  ];
}
