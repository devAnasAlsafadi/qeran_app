import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/error_codes.dart';
import 'block_action_state.dart';

/// Where a block starts, which decides the call it makes: a profile's ⋮
/// through the block feature, a Community comment's ⋮ through Community
/// (Q3). DI picks the call.
enum BlockOrigin { profile, community }

/// Blocks one member by id.
typedef BlockCall = Future<Either<Failure, void>> Function(String userId);

/// Performs a single block action (a profile's ⋮, a gallery, a Community
/// comment's ⋮). On success — or on the neutral TARGET_USER_NOT_FOUND — it
/// signals the caller to remove the target from view. Screen-scoped (factory
/// in DI).
class BlockActionCubit extends Cubit<BlockActionState>
    with SafeEmit<BlockActionState> {
  final BlockCall _block;

  BlockActionCubit({required BlockCall block})
    : _block = block,
      super(const BlockActionState());

  Future<void> block(String targetUserId) async {
    if (state.blocking) return;
    emit(state.copyWith(blocking: true));

    final result = await _block(targetUserId);
    if (isClosed) return;

    result.fold(
      (failure) => _onFailure(failure, targetUserId),
      (_) => _removed(targetUserId, LocaleKeys.block_success),
    );
  }

  void _onFailure(Failure failure, String targetUserId) {
    final code = failure is CodedServerFailure ? failure.errorCode : null;
    if (code == BlockErrorCodes.targetUserNotFound) {
      // Neutral: the target is gone / unavailable. Remove from view exactly
      // like a real block — NEVER reveal block status.
      return _removed(targetUserId, LocaleKeys.block_user_unavailable);
    }
    emit(
      state.copyWith(
        blocking: false,
        outcome: BlockActionOutcome.failure,
        eventVersion: state.eventVersion + 1,
        messageKey: LocaleKeys.errors_generic,
      ),
    );
  }

  void _removed(String targetUserId, String messageKey) => emit(
    state.copyWith(
      blocking: false,
      outcome: BlockActionOutcome.success,
      eventVersion: state.eventVersion + 1,
      blockedUserId: targetUserId,
      messageKey: messageKey,
    ),
  );
}
