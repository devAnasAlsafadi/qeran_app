import '../../shared/data/json_parsers.dart';
import '../../users/domain/entities/matchmaker_card_answer.dart';
import '../domain/entities/matchmaker_interest_image.dart';
import 'models/matchmaker_interest_image_model.dart';

/// Shared parsing helpers for the interests models.

/// Flagged answers (MatchmakerCardAnswerDto[]) → reused [MatchmakerCardAnswer].
List<MatchmakerCardAnswer> parseInterestAnswers(Object? raw) => parseMapList(raw)
    .map(
      (a) => MatchmakerCardAnswer(
        questionId: parseInt(a['questionId']),
        question: parseString(a['question']),
        answer: parseString(a['answer']),
      ),
    )
    .toList(growable: false);

/// One ProfileImageDto → entity (url absolutized); `null` when absent.
MatchmakerInterestImage? parseInterestImage(Object? raw) {
  final map = parseNullableMap(raw);
  return map == null ? null : MatchmakerInterestImageModel.fromJson(map).toEntity();
}

/// A ProfileImageDto[] → entities (urls absolutized).
List<MatchmakerInterestImage> parseInterestImages(Object? raw) =>
    parseMapList(raw)
        .map((m) => MatchmakerInterestImageModel.fromJson(m).toEntity())
        .toList(growable: false);
