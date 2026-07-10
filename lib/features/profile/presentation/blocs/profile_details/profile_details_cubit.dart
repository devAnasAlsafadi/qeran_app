import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';

import '../../../domain/entities/other_profile.dart';
import '../../../domain/entities/profile_fetch_outcome.dart';
import '../../../domain/usecases/get_profile_by_id_usecase.dart';
import 'profile_details_state.dart';

/// Screen-scoped cubit for [FullProfileDetailsScreen]. Drives the
/// seed → hydrate flow:
///
/// * with seed       → emit `Seeded` instantly, fetch in background
/// * without seed    → emit `Loading(seed: null)` (skeleton)
///
/// `PROFILE_NOT_FOUND` business failures land on `ProfileDetailsNotFound`
/// (the screen listener handles the auto-pop). Transport failures
/// preserve the seed when one exists so the user keeps reading while
/// we surface a non-blocking refresh-failed badge.
class ProfileDetailsCubit extends Cubit<ProfileDetailsState> with SafeEmit<ProfileDetailsState> {
  final GetProfileByIdUseCase _getProfileById;

  /// Monotonic counter — bumped each time a fresh
  /// [ProfileDetailsNotFound] is emitted so the screen-level listener
  /// fires its snackbar/auto-pop once per occurrence.
  int _notFoundVersion = 0;

  ProfileDetailsCubit({required GetProfileByIdUseCase getProfileById})
      : _getProfileById = getProfileById,
        super(const ProfileDetailsInitial());

  /// Initial entry. [seed] is optional — Discovery / Matches / Likes
  /// pass a partial preview; chat tap passes null.
  Future<void> init({required String userId, OtherProfile? seed}) async {
    if (seed != null) {
      emit(ProfileDetailsSeeded(seed));
    } else {
      emit(const ProfileDetailsLoading());
    }
    await _hydrate(userId, seed);
  }

  /// Pull-to-refresh. Keeps the seed (if any) while the fetch runs so
  /// the user never loses what they were reading.
  Future<void> refresh(String userId) async {
    final current = state;
    final seed = switch (current) {
      ProfileDetailsLoaded(:final profile) => profile,
      ProfileDetailsSeeded(:final seed) => seed,
      ProfileDetailsLoading(:final seed?) => seed,
      ProfileDetailsFailure(:final seed?) => seed,
      _ => null,
    };
    if (seed != null) {
      emit(ProfileDetailsLoading(seed: seed));
    } else {
      emit(const ProfileDetailsLoading());
    }
    await _hydrate(userId, seed);
  }

  Future<void> _hydrate(String userId, OtherProfile? seed) async {
    final result = await _getProfileById(userId);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Profile hydrate failed id=$userId message="${failure.message}"',
          tag: 'PROFILE',
        );
        emit(ProfileDetailsFailure(message: failure.message, seed: seed));
      },
      (outcome) => _emitOutcome(outcome),
    );
  }

  void _emitOutcome(ProfileFetchOutcome outcome) {
    switch (outcome) {
      case ProfileFetched(:final profile):
        emit(ProfileDetailsLoaded(profile));
      case ProfileNotFoundOutcome():
        _notFoundVersion += 1;
        emit(ProfileDetailsNotFound(eventVersion: _notFoundVersion));
      case ProfileUnauthorizedOutcome():
        // Surface as a failure with no seed so the global session
        // observer can react. The 401 path is shared infra; we don't
        // duplicate the routing here.
        emit(const ProfileDetailsFailure(message: 'unauthorized'));
    }
  }
}
