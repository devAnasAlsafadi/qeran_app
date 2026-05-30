/// Status of a case's formal request (`formalRequest.status`), parsed from
/// the wire string — never the int `statusCode` (strings are the source of
/// truth per the backend contract).
///
/// [allowedNext] encodes the server-validated transition graph the 3b
/// status-update flow uses to show only legal next actions; the server
/// stays authoritative (`INVALID_STATUS_TRANSITION`). [apiValue] is the
/// verbatim PascalCase value the status POST expects.
enum FormalRequestStatus {
  waitingForParentAppointment,
  parentsVisited,
  successfullyClosed,
  compatibilityClosed,
  compatibilityCancelled,
  unknown;

  static FormalRequestStatus fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'waitingforparentappointment':
        return FormalRequestStatus.waitingForParentAppointment;
      case 'parentsvisited':
        return FormalRequestStatus.parentsVisited;
      case 'successfullyclosed':
        return FormalRequestStatus.successfullyClosed;
      case 'compatibilityclosed':
        return FormalRequestStatus.compatibilityClosed;
      case 'compatibilitycancelled':
        return FormalRequestStatus.compatibilityCancelled;
      default:
        return FormalRequestStatus.unknown;
    }
  }

  /// Verbatim PascalCase value sent by the status POST. [unknown] has none.
  String? get apiValue => switch (this) {
        FormalRequestStatus.waitingForParentAppointment =>
          'WaitingForParentAppointment',
        FormalRequestStatus.parentsVisited => 'ParentsVisited',
        FormalRequestStatus.successfullyClosed => 'SuccessfullyClosed',
        FormalRequestStatus.compatibilityClosed => 'CompatibilityClosed',
        FormalRequestStatus.compatibilityCancelled => 'CompatibilityCancelled',
        FormalRequestStatus.unknown => null,
      };

  /// Server-validated transitions: 1→{2,4,5}, 2→{3,4,5}, 3/4/5 terminal.
  Set<FormalRequestStatus> get allowedNext => switch (this) {
        FormalRequestStatus.waitingForParentAppointment => const {
            FormalRequestStatus.parentsVisited,
            FormalRequestStatus.compatibilityClosed,
            FormalRequestStatus.compatibilityCancelled,
          },
        FormalRequestStatus.parentsVisited => const {
            FormalRequestStatus.successfullyClosed,
            FormalRequestStatus.compatibilityClosed,
            FormalRequestStatus.compatibilityCancelled,
          },
        FormalRequestStatus.successfullyClosed ||
        FormalRequestStatus.compatibilityClosed ||
        FormalRequestStatus.compatibilityCancelled ||
        FormalRequestStatus.unknown =>
          const <FormalRequestStatus>{},
      };

  bool get isTerminal => allowedNext.isEmpty;
}
