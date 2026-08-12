import 'package:equatable/equatable.dart';

import 'placement.dart';
import 'profile_image.dart';
import 'profile_status.dart';

/// My own profile as returned by `GET /api/profile`. Owner-only
/// fields (email, birthDate, status, isApproved on images) live here;
/// peer-facing screens use [OtherProfile] instead.
class MyProfile extends Equatable {
  final String id;

  /// The DISPLAY name — what other members see. Resolved through
  /// `parseDisplayName`, which never falls back to [realName].
  final String name;

  /// Legal/full name for formal proceedings. Owner-only; never shown to
  /// another user, and READ-ONLY from the app — the backend collects it at
  /// the formal-agreement stage. Null until then.
  final String? realName;

  /// The display name is still the server-assigned placeholder, so the member
  /// has never chosen one. While true the cooldown does not apply and they
  /// may edit freely.
  final bool isDefaultName;

  /// A real edit has happened and the 7-day cooldown is running. Ignored when
  /// [isDefaultName] is true.
  final bool isDisplayNameLocked;

  /// When the cooldown lifts. Null when the backend omits it — the lock is
  /// still honoured, just without a countdown.
  final DateTime? displayNameLockedUntil;
  final String? email;
  final String gender;
  final DateTime? birthDate;
  final int age;
  final ProfileStatus profileStatus;
  final bool hasAnsweredQuestions;
  final OwnerImage? profileImage;
  final List<OwnerImage> images;
  final List<Placement> placements;

  const MyProfile({
    required this.id,
    required this.name,
    this.realName,
    this.isDefaultName = false,
    this.isDisplayNameLocked = false,
    this.displayNameLockedUntil,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.age,
    required this.profileStatus,
    required this.hasAnsweredQuestions,
    required this.profileImage,
    required this.images,
    required this.placements,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        realName,
        isDefaultName,
        isDisplayNameLocked,
        displayNameLockedUntil,
        email,
        gender,
        birthDate,
        age,
        profileStatus,
        hasAnsweredQuestions,
        profileImage,
        images,
        placements,
      ];
}
