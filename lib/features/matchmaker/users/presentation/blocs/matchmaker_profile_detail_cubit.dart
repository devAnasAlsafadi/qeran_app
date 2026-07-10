import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/usecases/fetch_matchmaker_user_profile_usecase.dart';
import 'matchmaker_profile_detail_state.dart';

/// Drives the read-only matchmaker profile detail. Created per screen
/// (factory) with the target [userId]; [load] no-ops once loaded so a
/// rebuild doesn't refetch. Pull-to-refresh and retry both re-hit the API.
class MatchmakerProfileDetailCubit
    extends Cubit<MatchmakerProfileDetailState> with SafeEmit<MatchmakerProfileDetailState> {
  final FetchMatchmakerUserProfileUseCase _fetchProfile;
  final String userId;

  MatchmakerProfileDetailCubit({
    required this.userId,
    required FetchMatchmakerUserProfileUseCase fetchProfile,
  })  : _fetchProfile = fetchProfile,
        super(const MatchmakerProfileDetailInitial());

  /// First paint. No-op once loaded.
  Future<void> load() async {
    if (state is MatchmakerProfileDetailLoaded) return;
    emit(const MatchmakerProfileDetailLoading());
    await _fetch();
  }

  /// Pull-to-refresh — re-fetches without dropping the visible profile.
  Future<void> refresh() => _fetch();

  /// Retry after an error — re-enters the loading state.
  Future<void> retry() async {
    emit(const MatchmakerProfileDetailLoading());
    await _fetch();
  }

  Future<void> _fetch() async {
    final result = await _fetchProfile(userId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakerProfileDetailError(failure.message)),
      (profile) => emit(MatchmakerProfileDetailLoaded(profile)),
    );
  }
}
