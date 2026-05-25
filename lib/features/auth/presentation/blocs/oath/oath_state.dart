sealed class OathState {}

final class OathInitial extends OathState {}

final class OathSubmitting extends OathState {}

/// `/api/Questions/submit` succeeded after the user signed the oath.
/// Local flags `finishedQuestions` and `signedOath` have been persisted.
final class OathSubmitted extends OathState {}

final class OathFailure extends OathState {
  final String message;
  OathFailure(this.message);
}
