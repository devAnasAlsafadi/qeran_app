import 'package:equatable/equatable.dart';

/// Lightweight user record from `GET /api/users/{id}` — no images, no
/// placements. Use only when a name/age tuple is needed (e.g. notif
/// row, comment header). Not a substitute for [OtherProfile].
class BasicUser extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? gender;
  final int? age;
  final double? latitude;
  final double? longitude;

  const BasicUser({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.age,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [id, name, email, gender, age, latitude, longitude];
}
