import 'package:equatable/equatable.dart';

import 'matchmaker_me_image.dart';

/// The signed-in matchmaker's own account (`GET /matchmaker/me`). Editable from
/// the account screen: only [name] (PUT) and [image] (multipart) change from the
/// app; email / phone are admin-managed and read-only here.
class MatchmakerMe extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;

  /// Wire string — `"Male"` / `"Female"`.
  final String gender;
  final bool isActive;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final MatchmakerMeImage? image;

  const MatchmakerMe({
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

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        phoneNumber,
        gender,
        isActive,
        isPhoneVerified,
        createdAt,
        image,
      ];
}
