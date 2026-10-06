import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/community_post_change.dart';
import '../error_codes.dart';
import 'community_failure_classifier.dart';

/// What the repositories tell every screen about a post — read again, its
/// like changed, published or gone — so the feed, her posts and an open post
/// screen agree. One for the app (DI), shared by the member's repository and
/// the author's; app-lifetime, never closed.
class CommunityPostChanges {
  final _changes = StreamController<CommunityPostChange>.broadcast();

  Stream<CommunityPostChange> get stream => _changes.stream;

  void add(CommunityPostChange change) => _changes.add(change);

  /// [postId] gone, when [result] is the server saying so: [code] — a
  /// post's own `POST_NOT_FOUND`, or a report on it that finds it gone.
  void goneIf<T>(
    int postId,
    Either<Failure, T> result, {
    String code = CommunityErrorCodes.postNotFound,
  }) => result.fold((failure) {
    if (communityErrorCode(failure) == code) add(CommunityPostGone(postId));
  }, (_) {});
}
