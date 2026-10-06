import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/community_post_change.dart';
import '../error_codes.dart';
import 'community_failure_classifier.dart';

/// What the repository tells every screen about a post — read again, its like
/// changed, or gone — so the feed and an open post screen agree. App-lifetime,
/// like the repository: never closed.
class CommunityPostChanges {
  final _changes = StreamController<CommunityPostChange>.broadcast();

  Stream<CommunityPostChange> get stream => _changes.stream;

  void add(CommunityPostChange change) => _changes.add(change);

  /// [postId] gone, when [result] is the server saying so
  /// (`POST_NOT_FOUND`).
  void goneIf<T>(int postId, Either<Failure, T> result) =>
      result.fold((failure) {
        if (communityErrorCode(failure) == CommunityErrorCodes.postNotFound) {
          add(CommunityPostGone(postId));
        }
      }, (_) {});
}
