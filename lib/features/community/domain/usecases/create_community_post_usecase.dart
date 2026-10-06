import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/post_publish_outcome.dart';
import '../repositories/community_author_repository.dart';

/// 6.2 — her post, text only (media joins in later steps).
class CreateCommunityPostUseCase {
  final CommunityAuthorRepository _repository;
  const CreateCommunityPostUseCase(this._repository);

  Future<Either<Failure, PostPublishOutcome>> call({
    required String text,
    required String clientRequestId,
  }) => _repository.createPost(text: text, clientRequestId: clientRequestId);
}
