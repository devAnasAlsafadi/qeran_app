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

  /// The two negative terminals, named by what they MEAN rather than by their
  /// wire spelling. Every decision below and in presentation goes through
  /// these, so the wire mapping is declared once instead of being re-derived
  /// from a name at each use — and "Closed" reading neutral while it means an
  /// outcome is exactly the kind of thing that gets re-derived wrongly.
  ///
  /// The matchmaker tried and it did not work out. The server records this as
  /// `caseStatus = Failed`.
  static const FormalRequestStatus notSuccessful = compatibilityClosed;

  /// The case was called off rather than concluded — either party, or the
  /// matchmaker. The server records `caseStatus = Cancelled`.
  static const FormalRequestStatus calledOff = compatibilityCancelled;

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

  /// Server-validated transitions: 1→{2,5}, 2→{3,4,5}, 3/4/5 terminal. The
  /// server stays authoritative — an illegal move returns
  /// `INVALID_STATUS_TRANSITION` — but the UI is built from this so an illegal
  /// move is never offered in the first place.
  ///
  /// The two negative terminals used to be merged here. The backend once
  /// treated them identically, so offering both meant two buttons ("إغلاق" /
  /// "إلغاء") that did the same thing, and we collapsed them into one closure
  /// that always sent [calledOff]. They are now distinct outcomes —
  /// [notSuccessful] records `Failed`, [calledOff] records `Cancelled` — so
  /// the split is back, and a case can finally be marked as having not worked
  /// out rather than as merely called off.
  ///
  /// [notSuccessful] is offered ONLY after the families have met. Before that
  /// there is nothing to have failed, and the server rejects 1→4 outright; a
  /// matchmaker who wants out of an early case is calling it off, not
  /// reporting an outcome.
  Set<FormalRequestStatus> get allowedNext => switch (this) {
        FormalRequestStatus.waitingForParentAppointment => const {
            FormalRequestStatus.parentsVisited,
            FormalRequestStatus.calledOff,
          },
        FormalRequestStatus.parentsVisited => const {
            FormalRequestStatus.successfullyClosed,
            FormalRequestStatus.notSuccessful,
            FormalRequestStatus.calledOff,
          },
        FormalRequestStatus.successfullyClosed ||
        FormalRequestStatus.compatibilityClosed ||
        FormalRequestStatus.compatibilityCancelled ||
        FormalRequestStatus.unknown =>
          const <FormalRequestStatus>{},
      };

  bool get isTerminal => allowedNext.isEmpty;
}
