import 'other_profile.dart';

/// Typed outcomes for `GET /api/discovery/profiles/{userId}` and
/// `GET /api/users/{id}` (where the basic-user 404 maps to the same
/// not-found surface).
///
/// `Left(Failure)` covers transport-class problems. The successful
/// envelope plus the documented `PROFILE_NOT_FOUND` / `USER_NOT_FOUND`
/// business errors land here as `Right(ProfileFetchOutcome)` so the
/// presentation layer can branch with an exhaustive `switch`.
sealed class ProfileFetchOutcome {
  const ProfileFetchOutcome();
}

final class ProfileFetched extends ProfileFetchOutcome {
  final OtherProfile profile;
  const ProfileFetched(this.profile);
}

final class ProfileNotFoundOutcome extends ProfileFetchOutcome {
  final String serverMessage;
  const ProfileNotFoundOutcome({required this.serverMessage});
}

final class ProfileUnauthorizedOutcome extends ProfileFetchOutcome {
  final String serverMessage;
  const ProfileUnauthorizedOutcome({required this.serverMessage});
}
