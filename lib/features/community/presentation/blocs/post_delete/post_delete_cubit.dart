import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/state/safe_emit.dart';
import '../../../domain/usecases/delete_community_post_usecase.dart';

enum PostDeleteStatus { idle, deleting, deleted, failed }

/// Where her delete of a post stands. [attempt] tells two failures apart.
class PostDeleteState extends Equatable {
  const PostDeleteState({
    this.status = PostDeleteStatus.idle,
    this.postId,
    this.attempt = 0,
  });

  final PostDeleteStatus status;
  final int? postId;
  final int attempt;

  /// Her own delete is on its way or done: the post going is her doing.
  bool get leaving =>
      status == PostDeleteStatus.deleting || status == PostDeleteStatus.deleted;

  @override
  List<Object?> get props => [status, postId, attempt];
}

/// Deleting her own post (B7–B9, 6.3): one at a time. Done, the post leaves
/// every list and screen through the repository's change stream; the
/// screens say so with this state.
class PostDeleteCubit extends Cubit<PostDeleteState>
    with SafeEmit<PostDeleteState> {
  PostDeleteCubit({required DeleteCommunityPostUseCase deletePost})
    : _deletePost = deletePost,
      super(const PostDeleteState());

  final DeleteCommunityPostUseCase _deletePost;

  Future<void> delete(int postId) async {
    if (state.status == PostDeleteStatus.deleting) return;
    final attempt = state.attempt + 1;
    emit(
      PostDeleteState(
        status: PostDeleteStatus.deleting,
        postId: postId,
        attempt: attempt,
      ),
    );
    final result = await _deletePost(postId);
    final status = result.fold(
      (_) => PostDeleteStatus.failed,
      (_) => PostDeleteStatus.deleted,
    );
    emit(PostDeleteState(status: status, postId: postId, attempt: attempt));
  }
}
