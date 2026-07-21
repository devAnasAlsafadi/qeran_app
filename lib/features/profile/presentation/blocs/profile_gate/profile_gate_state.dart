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

/// Status resolved from `GET /api/profile`. The same fetch also carries the
/// signed-in user's identity — [name] and [photoUrl] are retained here (rather
/// than discarded) so the settings hero can show the real profile without a
/// second `GET /api/profile`. Both are null when the payload omitted them
/// (the hero then falls back cleanly to the monogram / generic label).
final class ProfileGateResolved extends ProfileGateState {
  final ProfileStatus status;

  /// The user's display name from the profile payload.
  final String? name;

  /// Absolute URL of the user's OWN profile photo (API-origin — needs the
  /// Bearer token to load). Null when no photo is set.
  final String? photoUrl;

  const ProfileGateResolved(this.status, {this.name, this.photoUrl});
}

/// Fetch failed or the status was unrecognised — the gate FAILS OPEN
/// (treated as not gated), so a transient error never blocks an approved user.
final class ProfileGateUnavailable extends ProfileGateState {
  const ProfileGateUnavailable();
}
