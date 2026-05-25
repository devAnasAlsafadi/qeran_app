import '../../domain/entities/formal_request.dart';
import '../json_parsers.dart';

class FormalRequestModel {
  final int id;
  final String maleUserId;
  final String maleUserName;
  final String femaleUserId;
  final String femaleUserName;
  final String status;
  final String statusNameAr;
  final String statusNameEn;
  final DateTime? updatedByMatchmakerAt;
  final DateTime createdAt;

  const FormalRequestModel({
    required this.id,
    required this.maleUserId,
    required this.maleUserName,
    required this.femaleUserId,
    required this.femaleUserName,
    required this.status,
    required this.statusNameAr,
    required this.statusNameEn,
    required this.updatedByMatchmakerAt,
    required this.createdAt,
  });

  /// Defensive parser — every optional field falls back to a safe
  /// default so a missing key never crashes the matches load. Every
  /// string field tolerates an unexpected int from the backend (the
  /// `status` field has been observed to flip between the enum
  /// string `"WaitingForParentAppointment"` and the numeric code).
  static FormalRequestModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return FormalRequestModel(
      id: parseInt(raw['id']),
      maleUserId: parseString(raw['maleUserId']),
      maleUserName: parseString(raw['maleUserName']),
      femaleUserId: parseString(raw['femaleUserId']),
      femaleUserName: parseString(raw['femaleUserName']),
      status: parseString(raw['status']),
      statusNameAr: parseString(raw['statusNameAr']),
      statusNameEn: parseString(raw['statusNameEn']),
      updatedByMatchmakerAt: parseNullableDateTime(raw['updatedByMatchmakerAt']),
      createdAt: parseNullableDateTime(raw['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  FormalRequest toEntity() => FormalRequest(
        id: id,
        maleUserId: maleUserId,
        maleUserName: maleUserName,
        femaleUserId: femaleUserId,
        femaleUserName: femaleUserName,
        status: status,
        statusNameAr: statusNameAr,
        statusNameEn: statusNameEn,
        updatedByMatchmakerAt: updatedByMatchmakerAt,
        createdAt: createdAt,
      );
}
