import '../../../shared/data/json_parsers.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_image.dart';
import '../interest_parsers.dart';

/// Wire model for ArchiveItemDto. ⚠️ Least-confirmed shape — fields parsed
/// defensively across likely names: otherUserId / name / profileImage|image /
/// outcome|status|statusNameAr / age / answers.
class MatchmakerInterestArchiveItemModel {
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final String outcome;
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestArchiveItemModel({
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.outcome,
    required this.age,
    required this.answers,
  });

  factory MatchmakerInterestArchiveItemModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      MatchmakerInterestArchiveItemModel(
        otherUserId: parseString(
          json['otherUserId'] ?? json['profileId'] ?? json['userId'],
        ),
        name: parseString(json['otherUserName'] ?? json['name']),
        image: parseInterestImage(json['profileImage'] ?? json['image']),
        outcome: parseString(
          json['outcome'] ??
              json['statusNameAr'] ??
              json['statusName'] ??
              json['status'],
        ),
        age: parseNullableInt(json['age']),
        answers: parseInterestAnswers(json['answers']),
      );

  MatchmakerInterestArchiveItem toEntity() => MatchmakerInterestArchiveItem(
        otherUserId: otherUserId,
        name: name,
        image: image,
        outcome: outcome,
        age: age,
        answers: answers,
      );
}
