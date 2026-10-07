import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../domain/entities/community_comment.dart';
import '../likes.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

/// Clears a report flag for the post's author (5.3's dismiss).
typedef DismissFlag = Future<Either<Failure, Unit>> Function(int flagId);

/// The comments cubit's reports, for the post's author only (E1–E3): she
/// keeps a reported comment or reply, and its flag goes in place. Deleting
/// one is [CommentRemoval]'s.
mixin CommentFlags on Cubit<CommunityCommentsState> {
  /// `DismissCommunityFlagUseCase`, as a function so the app builds the
  /// author's repository only when she keeps something.
  @protected
  DismissFlag? get dismissFlag;

  /// Her badges, read again once a flag is cleared — a backstop for the
  /// hub's `BadgeUpdated` (S16).
  @protected
  VoidCallback? get onFlagCleared;

  /// Keeps on their way, by flag: a second tap waits.
  final Set<int> _keeping = {};

  /// Keeps [comment]: `dismiss` clears its flag for her (the report stays
  /// with admin). The flag leaves the row and the screen says so; a failure
  /// keeps it, and says that.
  Future<void> keep(CommunityComment comment) async {
    final flag = comment.flag;
    final dismiss = dismissFlag;
    if (flag == null || dismiss == null || !_keeping.add(flag.id)) return;
    final result = await dismiss(flag.id);
    _keeping.remove(flag.id);
    result.fold(
      (_) => emit(state.withEvent(CommunityCommentsEvent.keepFailed)),
      (_) {
        final threads = withCommentChanged(
          state.threads,
          comment.id,
          (c) => c.withoutFlag(),
        );
        emit(
          state
              .copyWith(threads: threads)
              .withEvent(
                comment.isReply
                    ? CommunityCommentsEvent.keptReply
                    : CommunityCommentsEvent.kept,
              ),
        );
        onFlagCleared?.call();
      },
    );
  }
}
