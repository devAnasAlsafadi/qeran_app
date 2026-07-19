import 'package:equatable/equatable.dart';

import '../../domain/entities/blocked_user.dart';

enum BlockedListStatus { loading, loaded, error }

class BlockedListState extends Equatable {
  final BlockedListStatus status;
  final List<BlockedUser> users;

  /// Localized key for a load failure (status == error).
  final String? errorKey;

  /// userId whose unblock is in flight (its row shows a spinner); null = idle.
  final String? unblockingId;

  /// One-shot signal for the unblock-outcome snackbar (increments per action).
  final int actionVersion;
  final String? actionMessageKey;

  const BlockedListState({
    this.status = BlockedListStatus.loading,
    this.users = const [],
    this.errorKey,
    this.unblockingId,
    this.actionVersion = 0,
    this.actionMessageKey,
  });

  @override
  List<Object?> get props =>
      [status, users, errorKey, unblockingId, actionVersion, actionMessageKey];
}
