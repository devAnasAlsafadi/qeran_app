import '../../../domain/entities/profile_status.dart';

/// State of the app-scoped approval gate (see [ProfileGateCubit]).
sealed class ProfileGateState {
  const ProfileGateState();
}

/// Not fetched yet.
final class ProfileGateInitial extends ProfileGateState {
  const ProfileGateInitial();
}

/// Fetch in flight.
final class ProfileGateLoading extends ProfileGateState {
  const ProfileGateLoading();
}

/// Status resolved from `GET /api/profile`.
final class ProfileGateResolved extends ProfileGateState {
  final ProfileStatus status;
  const ProfileGateResolved(this.status);
}

/// Fetch failed or the status was unrecognised — the gate FAILS OPEN
/// (treated as not gated), so a transient error never blocks an approved user.
final class ProfileGateUnavailable extends ProfileGateState {
  const ProfileGateUnavailable();
}
