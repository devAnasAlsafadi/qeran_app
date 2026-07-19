import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_state.dart';

import '../../domain/usecases/delete_matchmaker_account_usecase.dart';

/// Permanent Moderator account deletion — mirrors the user [DeleteAccountCubit]
/// exactly: `DELETE /matchmaker/me/account`, then the required cleanup order
/// (best-effort device unlink → full local wipe) and a one-shot success outcome.
/// Reuses the shared [DeleteAccountState]. Screen-scoped (factory in DI).
class MatchmakerDeleteAccountCubit extends Cubit<DeleteAccountState>
    with SafeEmit<DeleteAccountState> {
  final DeleteMatchmakerAccountUseCase _deleteAccount;
  final DeviceBootstrapService _deviceBootstrap;
  final UserSessionCubit _session;

  MatchmakerDeleteAccountCubit({
    required DeleteMatchmakerAccountUseCase deleteAccount,
    required DeviceBootstrapService deviceBootstrap,
    required UserSessionCubit session,
  })  : _deleteAccount = deleteAccount,
        _deviceBootstrap = deviceBootstrap,
        _session = session,
        super(const DeleteAccountState());

  Future<void> delete() async {
    if (state.deleting) return; // single in-flight guard
    emit(state.copyWith(deleting: true, clearError: true));

    final result = await _deleteAccount();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        AppLogger.warning(
          'DELETE matchmaker account failed raw="${failure.message}"',
          tag: 'MM-DELETE-ACCOUNT',
        );
        emit(DeleteAccountState(
          outcome: DeleteAccountOutcome.failure,
          eventVersion: state.eventVersion + 1,
          errorKey: failure.message,
        ));
      },
      (_) async {
        // Required order — guard so a cleanup hiccup can't swallow the
        // (already-committed) deletion; the Moderator must not stay logged in.
        try {
          await _deviceBootstrap.unlinkSilently();
          await _session.wipeAllLocalData();
        } catch (e, s) {
          AppLogger.error(
            'post-delete cleanup error',
            error: e,
            stack: s,
            tag: 'MM-DELETE-ACCOUNT',
          );
        }
        if (isClosed) return;
        emit(DeleteAccountState(
          outcome: DeleteAccountOutcome.success,
          eventVersion: state.eventVersion + 1,
        ));
      },
    );
  }
}
