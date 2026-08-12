import 'package:equatable/equatable.dart';

import 'compatibility_case_stage.dart';

/// Query sent to the server-backed compatibility list. Both fields are
/// optional and independent; when both are present the backend combines them
/// before pagination, so `totalCount` and `totalPages` stay truthful.
class MatchmakerCasesFilter extends Equatable {
  final CompatibilityCaseStage? stage;
  final bool? activeFormalRequest;

  const MatchmakerCasesFilter({this.stage, this.activeFormalRequest});

  bool get isActive => stage != null || activeFormalRequest != null;

  MatchmakerCasesFilter copyWith({
    CompatibilityCaseStage? stage,
    bool clearStage = false,
    bool? activeFormalRequest,
    bool clearFormalRequest = false,
  }) {
    return MatchmakerCasesFilter(
      stage: clearStage ? null : (stage ?? this.stage),
      activeFormalRequest: clearFormalRequest
          ? null
          : (activeFormalRequest ?? this.activeFormalRequest),
    );
  }

  @override
  List<Object?> get props => [stage, activeFormalRequest];
}
