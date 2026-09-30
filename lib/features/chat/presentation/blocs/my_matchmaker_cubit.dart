import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/entities/my_matchmaker_outcome.dart';
import '../../domain/usecases/get_my_matchmaker_usecase.dart';
import 'my_matchmaker_state.dart';

/// Keeps the shell's top bar told who the member's matchmaker is. The shell
/// reads it when it mounts and whenever the app returns to the foreground.
///
/// Never emits a loading state: a re-read happens behind a bar that is already
/// showing her, and must not blank it while it runs. For the same reason a
/// failed re-read keeps whatever is showing — a dropped connection says nothing
/// about who the matchmaker is.
class MyMatchmakerCubit extends Cubit<MyMatchmakerState>
    with SafeEmit<MyMatchmakerState> {
  final GetMyMatchmakerUseCase _getMyMatchmaker;

  MyMatchmakerCubit({required GetMyMatchmakerUseCase getMyMatchmaker})
    : _getMyMatchmaker = getMyMatchmaker,
      super(const MyMatchmakerUnknown());

  Future<void> refresh() async {
    final result = await _getMyMatchmaker();
    result.fold(
      (failure) => _keep('failure raw="${failure.message}"'),
      (outcome) => switch (outcome) {
        MyMatchmakerAssigned(:final info) => emit(MyMatchmakerKnown(info)),
        MyMatchmakerNotAssigned() => emit(const MyMatchmakerNone()),
        MyMatchmakerFailure(:final errorCode) => _keep('code="$errorCode"'),
      },
    );
  }

  void _keep(String why) =>
      AppLogger.warning('CHAT my-matchmaker — kept state, $why', tag: 'CHAT');
}
