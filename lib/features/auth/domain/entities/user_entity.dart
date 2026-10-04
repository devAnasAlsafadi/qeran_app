import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? token;
  final String? role;
  final bool? isPhoneVerified;
  final bool? hasAnsweredQuestions;

  const UserEntity({
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

  /// Whether this account is a matchmaker ("Moderator" on the server).
  ///
  /// The role arrives as a free string, so the comparison is case-insensitive
  /// and lives here once rather than at each call site — a role check spelled
  /// slightly differently in one place is a silent authorisation hole.
  bool get isMatchmaker => role?.toLowerCase() == 'moderator';

  /// The same user with [hasAnsweredQuestions] set; every other field kept.
  UserEntity copyWith({bool? hasAnsweredQuestions}) => UserEntity(
    id: id,
    name: name,
    email: email,
    phoneNumber: phoneNumber,
    photoUrl: photoUrl,
    token: token,
    role: role,
    isPhoneVerified: isPhoneVerified,
    hasAnsweredQuestions: hasAnsweredQuestions ?? this.hasAnsweredQuestions,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneNumber,
    photoUrl,
    token,
    role,
    isPhoneVerified,
    hasAnsweredQuestions,
  ];
}
