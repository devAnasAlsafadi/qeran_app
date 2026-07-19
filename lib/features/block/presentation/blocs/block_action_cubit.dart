import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/error_codes.dart';
import '../../domain/usecases/block_user_usecase.dart';
import 'block_action_state.dart';

/// Performs a single block action (from a discovery card ⋮ / gallery). On
/// success — or on the neutral TARGET_USER_NOT_FOUND — it signals the caller to
/// remove the target from view. Screen-scoped (factory in DI).
class BlockActionCubit extends Cubit<BlockActionState>
    with SafeEmit<BlockActionState> {
  final BlockUserUseCase _blockUser;

  BlockActionCubit({required BlockUserUseCase blockUser})
      : _blockUser = blockUser,
        super(const BlockActionState());

  Future<void> block(String targetUserId) async {
    if (state.blocking) return;
    emit(state.copyWith(blocking: true));

    final result = await _blockUser(targetUserId);
    if (isClosed) return;

    result.fold(
      (failure) {
        final code = failure is CodedServerFailure ? failure.errorCode : null;
        if (code == BlockErrorCodes.targetUserNotFound) {
          // Neutral: the target is gone / unavailable. Remove from view exactly
          // like a real block — NEVER reveal block status.
          emit(state.copyWith(
            blocking: false,
            outcome: BlockActionOutcome.success,
            eventVersion: state.eventVersion + 1,
            blockedUserId: targetUserId,
            messageKey: LocaleKeys.block_user_unavailable,
          ));
        } else {
          emit(state.copyWith(
            blocking: false,
            outcome: BlockActionOutcome.failure,
            eventVersion: state.eventVersion + 1,
            messageKey: LocaleKeys.errors_generic,
          ));
        }
      },
      (_) => emit(state.copyWith(
        blocking: false,
        outcome: BlockActionOutcome.success,
        eventVersion: state.eventVersion + 1,
        blockedUserId: targetUserId,
        messageKey: LocaleKeys.block_success,
      )),
    );
  }
}
