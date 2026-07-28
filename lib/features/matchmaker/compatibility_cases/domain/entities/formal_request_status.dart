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
  ///
  /// [compatibilityClosed] keeps a wire value so an existing closed case still
  /// round-trips, but it is never SENT — it is absent from every [allowedNext]
  /// set (see the merge note there).
  String? get apiValue => switch (this) {
        FormalRequestStatus.waitingForParentAppointment =>
          'WaitingForParentAppointment',
        FormalRequestStatus.parentsVisited => 'ParentsVisited',
        FormalRequestStatus.successfullyClosed => 'SuccessfullyClosed',
        FormalRequestStatus.compatibilityClosed => 'CompatibilityClosed',
        FormalRequestStatus.compatibilityCancelled => 'CompatibilityCancelled',
        FormalRequestStatus.unknown => null,
      };

  /// Server-validated transitions: 1→{2,5}, 2→{3,5}, 3/4/5 terminal.
  ///
  /// `CompatibilityClosed(4)` and `CompatibilityCancelled(5)` are both negative
  /// terminal states and the backend treats them identically, so the two used
  /// to appear here as two separate buttons ("إغلاق" / "إلغاء") that did the
  /// same thing. They are merged: we offer ONE closure and always send
  /// `CompatibilityCancelled`, which is legal from both stages. `4` survives
  /// only for DISPLAYING cases closed before the merge.
  Set<FormalRequestStatus> get allowedNext => switch (this) {
        FormalRequestStatus.waitingForParentAppointment => const {
            FormalRequestStatus.parentsVisited,
            FormalRequestStatus.compatibilityCancelled,
          },
        FormalRequestStatus.parentsVisited => const {
            FormalRequestStatus.successfullyClosed,
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
