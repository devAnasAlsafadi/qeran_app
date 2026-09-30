import '../entities/my_matchmaker_outcome.dart';
import '../repositories/chat_repository.dart';

/// Who the matchmaker is, each time any screen reads it — see
/// [ChatRepository.myMatchmakerAnswers].
class WatchMyMatchmakerUseCase {
  final ChatRepository _repository;
  const WatchMyMatchmakerUseCase(this._repository);

  Stream<MyMatchmakerOutcome> call() => _repository.myMatchmakerAnswers;
}
