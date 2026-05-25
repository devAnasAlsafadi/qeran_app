import '../../domain/entities/basic_user.dart';
import '../json_parsers.dart';

class BasicUserModel {
  final String id;
  final String name;
  final String? email;
  final String? gender;
  final int? age;
  final double? latitude;
  final double? longitude;

  const BasicUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.age,
    required this.latitude,
    required this.longitude,
  });

  factory BasicUserModel.fromJson(Map<String, dynamic> json) {
    return BasicUserModel(
      id: parseString(json['id']),
      name: parseString(json['name']),
      email: parseNullableString(json['email']),
      gender: parseNullableString(json['gender']),
      age: parseNullableInt(json['age']),
      latitude: parseNullableDouble(json['latitude']),
      longitude: parseNullableDouble(json['longitude']),
    );
  }

  BasicUser toEntity() => BasicUser(
        id: id,
        name: name,
        email: email,
        gender: gender,
        age: age,
        latitude: latitude,
        longitude: longitude,
      );
}
