import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/usecases/get_blocked_users_usecase.dart';
import '../../domain/usecases/unblock_user_usecase.dart';
import 'blocked_list_state.dart';

/// Loads the blocked-users list and performs unblocks. States are constructed
/// directly (not copyWith) so nullable one-shot fields can be cleared cleanly.
class BlockedListCubit extends Cubit<BlockedListState>
    with SafeEmit<BlockedListState> {
  final GetBlockedUsersUseCase _getBlocked;
  final UnblockUserUseCase _unblock;

  BlockedListCubit({
    required GetBlockedUsersUseCase getBlocked,
    required UnblockUserUseCase unblock,
  })  : _getBlocked = getBlocked,
        _unblock = unblock,
        super(const BlockedListState());

  Future<void> load() async {
    emit(const BlockedListState(status: BlockedListStatus.loading));
    final result = await _getBlocked();
    if (isClosed) return;
    result.fold(
      (failure) => emit(BlockedListState(
        status: BlockedListStatus.error,
        errorKey: failure.message,
      )),
      (users) => emit(BlockedListState(
        status: BlockedListStatus.loaded,
        users: users,
      )),
    );
  }

  Future<void> unblock(String userId) async {
    final s = state;
    if (s.status != BlockedListStatus.loaded || s.unblockingId != null) return;
    emit(BlockedListState(
      status: BlockedListStatus.loaded,
      users: s.users,
      unblockingId: userId,
      actionVersion: s.actionVersion,
    ));

    final result = await _unblock(userId);
    if (isClosed) return;
    result.fold(
      (_) => emit(BlockedListState(
        status: BlockedListStatus.loaded,
        users: state.users,
        actionVersion: state.actionVersion + 1,
        actionMessageKey: LocaleKeys.block_unblock_failed,
      )),
      (_) => emit(BlockedListState(
        status: BlockedListStatus.loaded,
        users: state.users
            .where((u) => u.userId != userId)
            .toList(growable: false),
        actionVersion: state.actionVersion + 1,
        actionMessageKey: LocaleKeys.block_unblocked,
      )),
    );
  }
}
