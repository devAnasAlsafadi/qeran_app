import 'package:equatable/equatable.dart';

import '../../../domain/entities/other_profile.dart';

/// Sealed state for [ProfileDetailsCubit]. Each variant either renders
/// the screen (seed/loaded/with-seed-loading) or a dedicated empty/
/// error/not-found view.
///
/// `notAvailableEventVersion` ticks each time [ProfileDetailsNotFound]
/// is freshly emitted so the screen-level listener can fire its
/// auto-pop snackbar exactly once per occurrence — unrelated state
/// changes never re-trigger it.
sealed class ProfileDetailsState extends Equatable {
  const ProfileDetailsState();

  @override
  List<Object?> get props => const [];
}

final class ProfileDetailsInitial extends ProfileDetailsState {
  const ProfileDetailsInitial();
}

final class ProfileDetailsSeeded extends ProfileDetailsState {
  final OtherProfile seed;
  const ProfileDetailsSeeded(this.seed);

  @override
  List<Object?> get props => [seed];
}

final class ProfileDetailsLoading extends ProfileDetailsState {
  /// When non-null the screen keeps painting the seed while the
  /// hydration call is in flight (soft refresh badge instead of full
  /// skeleton).
  final OtherProfile? seed;
  const ProfileDetailsLoading({this.seed});

  @override
  List<Object?> get props => [seed];
}

final class ProfileDetailsLoaded extends ProfileDetailsState {
  final OtherProfile profile;
  const ProfileDetailsLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

final class ProfileDetailsNotFound extends ProfileDetailsState {
  final int eventVersion;
  const ProfileDetailsNotFound({required this.eventVersion});

  @override
  List<Object?> get props => [eventVersion];
}

final class ProfileDetailsFailure extends ProfileDetailsState {
  final String message;
  final OtherProfile? seed;
  const ProfileDetailsFailure({required this.message, this.seed});

  @override
  List<Object?> get props => [message, seed];
}
