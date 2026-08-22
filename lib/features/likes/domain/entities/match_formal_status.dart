/// The matchmaker's formal-request status as the MEMBER's matches feed carries
/// it (`formalRequest.status` on `/api/matches`).
///
/// Deliberately a likes-module enum rather than an import of the matchmaker's
/// `FormalRequestStatus`. Likes imports nothing from matchmaker today, and
/// `matchmaker/shared/data/json_parsers.dart` states the convention outright:
/// each feature module keeps its own.
///
/// [fromWire] tolerates BOTH wire shapes because this field has been observed
/// flipping between them — see `FormalRequestModel`'s parser note. The numeric
/// codes are 1-BASED, not 0-based, which is the trap: an off-by-one here puts
/// the member on the wrong journey node and raises nothing anywhere.
enum MatchFormalStatus {
  waitingForParentAppointment,
  parentsVisited,
  successfullyClosed,
  compatibilityClosed,
  compatibilityCancelled,

  /// Defensive — an unrecognised value. Never a reason to hide the journey:
  /// a formal request exists, so the matchmaker is involved.
  unknown;

  static MatchFormalStatus fromWire(Object? raw) {
    if (raw is String) {
      switch (raw.toLowerCase()) {
        case 'waitingforparentappointment':
          return MatchFormalStatus.waitingForParentAppointment;
        case 'parentsvisited':
          return MatchFormalStatus.parentsVisited;
        case 'successfullyclosed':
          return MatchFormalStatus.successfullyClosed;
        case 'compatibilityclosed':
          return MatchFormalStatus.compatibilityClosed;
        case 'compatibilitycancelled':
          return MatchFormalStatus.compatibilityCancelled;
      }
    }
    // Legacy/numeric shape (int, or a numeric string like "3").
    final code = switch (raw) {
      int n => n,
      String s => int.tryParse(s),
      _ => null,
    };
    return switch (code) {
      1 => MatchFormalStatus.waitingForParentAppointment,
      2 => MatchFormalStatus.parentsVisited,
      3 => MatchFormalStatus.successfullyClosed,
      4 => MatchFormalStatus.compatibilityClosed,
      5 => MatchFormalStatus.compatibilityCancelled,
      _ => MatchFormalStatus.unknown,
    };
  }
}
