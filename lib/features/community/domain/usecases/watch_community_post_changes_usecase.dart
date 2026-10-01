import '../entities/community_post_change.dart';
import '../repositories/community_repository.dart';

class WatchCommunityPostChangesUseCase {
  final CommunityRepository _repository;
  const WatchCommunityPostChangesUseCase(this._repository);

  Stream<CommunityPostChange> call() => _repository.postChanges;
}
