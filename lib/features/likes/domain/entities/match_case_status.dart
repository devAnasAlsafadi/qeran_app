/// How the compatibility case ENDED, if it has (`caseStatus` on
/// `/api/matches`).
///
/// Separate from [MatchCaseStage] on purpose, and the separation is the point:
/// a case can be cancelled while standing on any stage, so "where it got to"
/// and "how it finished" cannot share one field without the stage numbering
/// needing a hole punched in it for every way a journey can stop.
enum MatchCaseStatus {
  /// Still running. Also what an ABSENT field means — see [fromWire].
  active,

  /// Either member, or the matchmaker, called it off.
  cancelled,

  /// The matchmaker recorded that it did not work out.
  failed,

  /// The marriage went ahead.
  completed,

  /// Present but unrecognised. Distinct from absent, which is [active].
  unknown;

  /// Absent means [active] — the server's documented contract, and it also
  /// covers a payload cached before the field shipped.
  ///
  /// A value that is present but unrecognised is [unknown] instead. Folding
  /// the two together would let a future status the client has never heard of
  /// render as a healthy live case.
  static MatchCaseStatus fromWire(Object? raw) {
    if (raw == null) return MatchCaseStatus.active;
    if (raw is String) {
      switch (raw.toLowerCase()) {
        case '':
          return MatchCaseStatus.active;
        case 'active':
          return MatchCaseStatus.active;
        case 'cancelled':
        case 'canceled':
          return MatchCaseStatus.cancelled;
        case 'failed':
          return MatchCaseStatus.failed;
        case 'completed':
          return MatchCaseStatus.completed;
      }
    }
    return MatchCaseStatus.unknown;
  }

  /// Whether the journey has stopped, whatever the reason.
  bool get isEnded =>
      this == MatchCaseStatus.cancelled ||
      this == MatchCaseStatus.failed ||
      this == MatchCaseStatus.completed;
}
