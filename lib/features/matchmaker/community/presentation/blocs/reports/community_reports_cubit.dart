import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/community/domain/entities/community_flagged_item.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/usecases/delete_community_comment_usecase.dart';
import 'package:qeran/features/community/domain/usecases/dismiss_community_flag_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_flags_usecase.dart';

import 'community_reports_state.dart';

export 'community_reports_state.dart';

/// «البلاغات» (E7–E10): the open reports on comments and replies in her
/// posts, a page at a time. She keeps an item (its flag clears) or deletes
/// it, and its row leaves either way; her badges are read again (S16).
class CommunityReportsCubit extends Cubit<CommunityReportsState>
    with SafeEmit<CommunityReportsState> {
  CommunityReportsCubit({
    required GetCommunityFlagsUseCase getFlags,
    required DismissCommunityFlagUseCase dismissFlag,
    required DeleteCommunityCommentUseCase deleteComment,
    VoidCallback? onFlagCleared,
  }) : _getFlags = getFlags,
       _dismissFlag = dismissFlag,
       _deleteComment = deleteComment,
       _onFlagCleared = onFlagCleared,
       super(const CommunityReportsState());

  final GetCommunityFlagsUseCase _getFlags;
  final DismissCommunityFlagUseCase _dismissFlag;
  final DeleteCommunityCommentUseCase _deleteComment;
  final VoidCallback? _onFlagCleared;

  /// The first page — on opening, and from the error's retry (E10).
  Future<void> load() async {
    emit(state.copyWith(status: CommunityReportsStatus.loading));
    final result = await _getFlags(page: 1);
    result.fold(
      (_) => emit(state.copyWith(status: CommunityReportsStatus.failure)),
      (page) => emit(_firstPage(page)),
    );
  }

  /// Read again when she's back from a post it opened (S17): the rows stay
  /// until the new ones land, and stay if that fails.
  Future<void> reload() async {
    if (state.status != CommunityReportsStatus.loaded &&
        state.status != CommunityReportsStatus.empty) {
      return load();
    }
    final result = await _getFlags(page: 1);
    result.fold((_) {}, (page) => emit(_firstPage(page)));
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.status != CommunityReportsStatus.loaded ||
        !s.hasMore ||
        s.loadingMore) {
      return;
    }
    emit(s.copyWith(loadingMore: true));
    final result = await _getFlags(page: s.page + 1);
    result.fold(
      (_) => emit(state.copyWith(loadingMore: false)),
      (page) => emit(
        state.copyWith(
          items: _merged(state.items, page.items),
          page: page.pageNumber,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  /// Keeps [item]: its flag clears for her (the report stays with admin).
  Future<void> keep(CommunityFlaggedItem item) async {
    if (!_begin(item)) return;
    final result = await _dismissFlag(item.flag.id);
    final reply = item.comment.isReply;
    result.fold(
      (_) => _failed(item, CommunityReportsEvent.keepFailed),
      (_) => _answered(
        item,
        reply ? CommunityReportsEvent.keptReply : CommunityReportsEvent.kept,
      ),
    );
  }

  /// Deletes [item] — a comment with its replies (D16), or a reply. One
  /// already gone counts as deleted.
  Future<void> delete(CommunityFlaggedItem item) async {
    if (!_begin(item)) return;
    final result = await _deleteComment(item.comment.id);
    final reply = item.comment.isReply;
    result.fold(
      (_) => _failed(
        item,
        reply
            ? CommunityReportsEvent.deleteReplyFailed
            : CommunityReportsEvent.deleteFailed,
      ),
      (_) => _answered(
        item,
        reply
            ? CommunityReportsEvent.deletedReply
            : CommunityReportsEvent.deleted,
        deleted: true,
      ),
    );
  }

  CommunityReportsState _firstPage(CommunityPage<CommunityFlaggedItem> page) =>
      state.copyWith(
        status: page.items.isEmpty
            ? CommunityReportsStatus.empty
            : CommunityReportsStatus.loaded,
        items: page.items,
        page: page.pageNumber,
        hasMore: page.hasMore,
        loadingMore: false,
      );

  /// Marks [item] as being answered; false when it already is.
  bool _begin(CommunityFlaggedItem item) {
    if (state.answering.contains(item.flag.id)) return false;
    emit(state.copyWith(answering: {...state.answering, item.flag.id}));
    return true;
  }

  void _failed(CommunityFlaggedItem item, CommunityReportsEvent event) =>
      emit(state.copyWith(answering: _without(item)).withEvent(event));

  /// Its row leaves — and with a deleted comment, the rows of its replies.
  void _answered(
    CommunityFlaggedItem item,
    CommunityReportsEvent event, {
    bool deleted = false,
  }) {
    final gone = item.comment.id;
    final items = [
      for (final other in state.items)
        if (other.flag.id != item.flag.id &&
            !(deleted && other.comment.parentCommentId == gone))
          other,
    ];
    final empty = items.isEmpty && !state.hasMore;
    emit(
      state
          .copyWith(
            items: items,
            answering: _without(item),
            status: empty ? CommunityReportsStatus.empty : null,
          )
          .withEvent(event),
    );
    _onFlagCleared?.call();
  }

  Set<int> _without(CommunityFlaggedItem item) =>
      state.answering.difference({item.flag.id});

  /// The next page's rows after [items], each flag once.
  static List<CommunityFlaggedItem> _merged(
    List<CommunityFlaggedItem> items,
    List<CommunityFlaggedItem> next,
  ) {
    final seen = {for (final item in items) item.flag.id};
    return [...items, ...next.where((item) => seen.add(item.flag.id))];
  }
}
