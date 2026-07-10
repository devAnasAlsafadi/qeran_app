import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/features/profile/domain/usecases/delete_account_usecase.dart';

import 'delete_account_state.dart';

/// Orchestrates permanent account deletion: `DELETE /api/Profile`, then — only
/// on success — the required cleanup order (best-effort device unlink → full
/// local wipe), then a one-shot success outcome. Single in-flight guard; the
/// outcome is signalled via [DeleteAccountState.eventVersion] (mirrors
/// `MatchmakerAccountCubit`). Screen-scoped (factory in DI).
class DeleteAccountCubit extends Cubit<DeleteAccountState> with SafeEmit<DeleteAccountState> {
  final DeleteAccountUseCase _deleteAccount;
  final DeviceBootstrapService _deviceBootstrap;
  final UserSessionCubit _session;

  DeleteAccountCubit({
    required DeleteAccountUseCase deleteAccount,
    required DeviceBootstrapService deviceBootstrap,
    required UserSessionCubit session,
  })  : _deleteAccount = deleteAccount,
        _deviceBootstrap = deviceBootstrap,
        _session = session,
        super(const DeleteAccountState());

  /// Permanently deletes the account. On success runs the required cleanup
  /// order then emits [DeleteAccountOutcome.success]; on a delete failure emits
  /// [DeleteAccountOutcome.failure] (nothing local is touched).
  ///
  /// A failed/missing unlink — or any cleanup hiccup — NEVER blocks success:
  /// once `DELETE` returns ok the account is gone server-side, so we always
  /// finish the wipe and emit success (the user must not be left logged-in).
  Future<void> delete() async {
    if (state.deleting) return; // single in-flight guard
    emit(state.copyWith(deleting: true, clearError: true));

    final result = await _deleteAccount();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        AppLogger.warning(
          'DELETE account failed raw="${failure.message}"',
          tag: 'DELETE-ACCOUNT',
        );
        emit(DeleteAccountState(
          outcome: DeleteAccountOutcome.failure,
          eventVersion: state.eventVersion + 1,
          errorKey: failure.message,
        ));
      },
      (_) async {
        // Required order — both never throw by contract, but guard anyway so a
        // cleanup error can't swallow the (already-committed) deletion.
        try {
          await _deviceBootstrap.unlinkSilently(); // fire-and-forget
          await _session.wipeAllLocalData();
        } catch (e, s) {
          AppLogger.error(
            'post-delete cleanup error',
            error: e,
            stack: s,
            tag: 'DELETE-ACCOUNT',
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
