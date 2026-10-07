import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/usecases/has_my_community_posts_usecase.dart';
import 'package:qeran/features/community/domain/usecases/watch_community_post_changes_usecase.dart';

/// Whether her Dashboard's Community section has posts to speak of (D35):
/// true or false once read, null until then or when it couldn't be — the
/// rows stay then. A post she makes turns it on at once; a post gone is
/// read again (it may have been her last).
class CommunityDashboardCubit extends Cubit<bool?> with SafeEmit<bool?> {
  CommunityDashboardCubit({
    required HasMyCommunityPostsUseCase hasPosts,
    required WatchCommunityPostChangesUseCase watchChanges,
  }) : _hasPosts = hasPosts,
       super(null) {
    _changes = watchChanges().listen(_onChange);
  }

  final HasMyCommunityPostsUseCase _hasPosts;
  late final StreamSubscription<CommunityPostChange> _changes;

  /// On the Dashboard's opening and its pull to refresh. A failure keeps
  /// what was known.
  Future<void> load() async {
    final result = await _hasPosts();
    result.fold((_) {}, emit);
  }

  void _onChange(CommunityPostChange change) => switch (change) {
    CommunityPostCreated() => emit(true),
    CommunityPostGone() => unawaited(load()),
    _ => null,
  };

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
