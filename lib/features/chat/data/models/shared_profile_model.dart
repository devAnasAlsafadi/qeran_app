import '../../domain/entities/shared_profile.dart';
import '../json_parsers.dart';
import 'shared_profile_answer_model.dart';
import 'shared_profile_image_model.dart';

class SharedProfileModel {
  final String id;
  final String name;
  final int? age;
  final double matchingScore;
  final List<SharedProfileImageModel> images;
  final List<SharedProfileAnswerModel> answers;

  const SharedProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.matchingScore,
    required this.images,
    required this.answers,
  });

  static SharedProfileModel? fromJson(Object? raw) {
    final map = parseNullableMap(raw);
    if (map == null) return null;
    return SharedProfileModel(
      id: parseString(map['id']),
      name: parseString(map['name']),
      age: parseNullableInt(map['age']),
      matchingScore: parseDouble(map['matchingScore']),
      images: _parseImages(map['images']),
      answers: _parseAnswers(map['answers']),
    );
  }

  static List<SharedProfileImageModel> _parseImages(Object? raw) {
    if (raw is! List) return const [];
    final out = <SharedProfileImageModel>[];
    for (final item in raw) {
      final m = parseNullableMap(item);
      if (m != null) out.add(SharedProfileImageModel.fromJson(m));
    }
    return List.unmodifiable(out);
  }

  /// Tolerant: missing / null / non-list `answers` → empty. Skips any
  /// entry that isn't a parseable map and any with a blank answer.
  static List<SharedProfileAnswerModel> _parseAnswers(Object? raw) {
    if (raw is! List) return const [];
    final out = <SharedProfileAnswerModel>[];
    for (final item in raw) {
      final m = parseNullableMap(item);
      if (m == null) continue;
      final model = SharedProfileAnswerModel.fromJson(m);
      if (model.answer.trim().isEmpty) continue;
      out.add(model);
    }
    return List.unmodifiable(out);
  }

  SharedProfile toEntity() => SharedProfile(
        id: id,
        name: name,
        age: age,
        matchingScore: matchingScore,
        images: images.map((m) => m.toEntity()).toList(growable: false),
        answers: answers.map((m) => m.toEntity()).toList(growable: false),
      );
}
