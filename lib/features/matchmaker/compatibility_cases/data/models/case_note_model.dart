import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/case_note.dart';

/// Wire model for `CaseNoteDto {content, createdAt, updatedAt}`.
class CaseNoteModel {
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CaseNoteModel({
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory CaseNoteModel.fromJson(Map<String, dynamic> json) => CaseNoteModel(
        content: parseString(json['content']),
        createdAt: parseNullableDateTime(json['createdAt']),
        updatedAt: parseNullableDateTime(json['updatedAt']),
      );

  CaseNote toEntity() => CaseNote(
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
