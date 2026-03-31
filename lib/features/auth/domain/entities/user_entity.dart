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

  @override
  List<Object?> get props => [id, name, email, phoneNumber, photoUrl, token, role, isPhoneVerified, hasAnsweredQuestions];
}
