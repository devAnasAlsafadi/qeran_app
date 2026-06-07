import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_me.dart';
import 'matchmaker_me_image_model.dart';

/// Wire model for `GET /matchmaker/me` →
/// `{ userId, name, email, phoneNumber, gender, isActive, isPhoneVerified,
///   createdAt, profileImage:{id,url,isProfile} }`.
class MatchmakerMeModel {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String gender;
  final bool isActive;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final MatchmakerMeImageModel? image;

  const MatchmakerMeModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.isActive,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.image,
  });

  factory MatchmakerMeModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerMeModel(
        userId: parseString(json['userId']),
        name: parseString(json['name']),
        email: parseString(json['email']),
        phoneNumber: parseString(json['phoneNumber']),
        gender: parseString(json['gender']),
        isActive: parseBool(json['isActive']),
        isPhoneVerified: parseBool(json['isPhoneVerified']),
        createdAt: parseNullableDateTime(json['createdAt']),
        image: _parseImage(json['profileImage']),
      );

  static MatchmakerMeImageModel? _parseImage(Object? raw) {
    final map = parseNullableMap(raw);
    return map == null ? null : MatchmakerMeImageModel.fromJson(map);
  }

  MatchmakerMe toEntity() => MatchmakerMe(
        userId: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        gender: gender,
        isActive: isActive,
        isPhoneVerified: isPhoneVerified,
        createdAt: createdAt,
        image: image?.toEntity(),
      );
}
