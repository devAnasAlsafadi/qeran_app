import 'package:equatable/equatable.dart';

/// A candidate profile shown in the matching deck on the Home screen.
///
/// This is the domain shape — the data layer's `ProfileModel` will map onto
/// this entity. Today we feed it from mock data; the API binding lands later.
class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final int age;
  final String city;
  final String country;
  final String? occupation;
  final String? bio;
  final String? religion;
  final int? heightCm;
  final int? weightKg;

  /// Remote photo URL. Null/empty → render the privacy placeholder.
  final String? photoUrl;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.country,
    this.occupation,
    this.bio,
    this.religion,
    this.heightCm,
    this.weightKg,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    age,
    city,
    country,
    occupation,
    bio,
    religion,
    heightCm,
    weightKg,
    photoUrl,
  ];
}
