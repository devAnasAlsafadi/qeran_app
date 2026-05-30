import 'package:equatable/equatable.dart';
import 'package:qeran/core/enum/gender.dart';

/// One participant in a compatibility case (`myUser` / `otherUser`).
///
/// [profileImageUrl] is already absolute (the data layer runs the server's
/// relative path through `EndPoints.absoluteUrl`); `null` when the user has
/// no profile image. [age] and [gender] are newly-added server fields —
/// both nullable and absent from older payloads, so the card surfaces them
/// only when present.
class CaseUser extends Equatable {
  final String userId;
  final String firstName;
  final String? profileImageUrl;
  final int? age;
  final Gender? gender;
  final bool isAssignedToMe;

  const CaseUser({
    required this.userId,
    required this.firstName,
    required this.profileImageUrl,
    required this.age,
    required this.gender,
    required this.isAssignedToMe,
  });

  @override
  List<Object?> get props =>
      [userId, firstName, profileImageUrl, age, gender, isAssignedToMe];
}
