import '../../domain/entities/user_entity.dart';
import 'package:qeran/core/data/display_name.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? token;
  final String? role;
  final bool? isPhoneVerified;
  final bool? hasAnsweredQuestions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.token,
    this.role,
    this.isPhoneVerified,
    this.hasAnsweredQuestions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    // Tolerate a numeric id: a freshly-created (social) user row can come back
    // with `userId` as a JSON number, which a hard `as String` cast would crash
    // on. `.toString()` handles String / int / anything, defaulting to "".
    id: (json['userId'] ?? json['id'] ?? '').toString(),
    name: parseDisplayName(json),
    email: (json['email'] ?? '') as String,
    phoneNumber: json['phoneNumber'] as String?,
    photoUrl: json['photo_url'] as String?,
    token: json['token'] as String?,
    role: json['role'] as String?,
    isPhoneVerified: json['isPhoneVerified'] as bool?,
    hasAnsweredQuestions: json['hasAnsweredQuestions'] as bool?,
  );

  factory UserModel.fromFirebaseUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? token,
  }) => UserModel(
    id: uid,
    name: name,
    email: email,
    photoUrl: photoUrl,
    token: token,
  );

  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    phoneNumber: phoneNumber,
    photoUrl: photoUrl,
    token: token,
    role: role,
    isPhoneVerified: isPhoneVerified,
    hasAnsweredQuestions: hasAnsweredQuestions,
  );
}
