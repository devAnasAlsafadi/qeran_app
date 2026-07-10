import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';

import '../../../domain/usecases/get_my_profile_usecase.dart';
import 'my_profile_state.dart';

class MyProfileCubit extends Cubit<MyProfileState> with SafeEmit<MyProfileState> {
  final GetMyProfileUseCase _getMyProfile;

  MyProfileCubit({required GetMyProfileUseCase getMyProfile})
      : _getMyProfile = getMyProfile,
        super(const MyProfileInitial());

  Future<void> load() async {
    final current = state;
    final previous = switch (current) {
      MyProfileLoaded(:final profile) => profile,
      MyProfileFailure(:final previous?) => previous,
      MyProfileLoading(:final previous?) => previous,
      _ => null,
    };
    emit(MyProfileLoading(previous: previous));
    final result = await _getMyProfile();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'My profile load failed message="${failure.message}"',
          tag: 'PROFILE',
        );
        emit(MyProfileFailure(message: failure.message, previous: previous));
      },
      (profile) => emit(MyProfileLoaded(profile)),
    );
  }

  Future<void> refresh() => load();
}
