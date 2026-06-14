import '../../../shared/data/json_parsers.dart';
import '../../../users/domain/entities/matchmaker_card_answer.dart';
import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_image.dart';
import '../interest_parsers.dart';

/// Wire model for ArchiveItemDto. Confirmed fields: type ("like" |
/// "photo_exchange") / otherUserId / otherUserName / profileImage /
/// status (raw) / statusNameAr / statusNameEn (pre-translated) /
/// reason ("rejected" | "expired") / archivedAt / answers.
/// `archivedAt` is ignored (no countdown / timeline shown); the DTO has no age.
class MatchmakerInterestArchiveItemModel {
  final MatchmakerArchiveType type;
  final String otherUserId;
  final String name;
  final MatchmakerInterestImage? image;
  final String status;
  final String statusNameAr;
  final String statusNameEn;
  final MatchmakerArchiveReason reason;
  final List<MatchmakerCardAnswer> answers;

  const MatchmakerInterestArchiveItemModel({
    required this.type,
    required this.otherUserId,
    required this.name,
    required this.image,
    required this.status,
    required this.statusNameAr,
    required this.statusNameEn,
    required this.reason,
    required this.answers,
  });

  factory MatchmakerInterestArchiveItemModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      MatchmakerInterestArchiveItemModel(
        type: matchmakerArchiveTypeFromWire(json['type']),
        otherUserId: parseString(
          json['otherUserId'] ?? json['profileId'] ?? json['userId'],
        ),
        name: parseString(json['otherUserName'] ?? json['name']),
        image: parseInterestImage(json['profileImage'] ?? json['image']),
        status: parseString(json['status']),
        statusNameAr: parseString(json['statusNameAr']),
        statusNameEn: parseString(json['statusNameEn']),
        reason: matchmakerArchiveReasonFromWire(json['reason']),
        answers: parseInterestAnswers(json['answers']),
      );

  MatchmakerInterestArchiveItem toEntity() => MatchmakerInterestArchiveItem(
        type: type,
        otherUserId: otherUserId,
        name: name,
        image: image,
        status: status,
        statusNameAr: statusNameAr,
        statusNameEn: statusNameEn,
        reason: reason,
        answers: answers,
      );
}
