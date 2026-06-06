import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_user_note.dart';

/// Wire model for `MatchmakerUserNoteDto {content, createdAt, updatedAt}`.
class MatchmakerUserNoteModel {
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MatchmakerUserNoteModel({
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory MatchmakerUserNoteModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerUserNoteModel(
        content: parseString(json['content']),
        createdAt: parseNullableDateTime(json['createdAt']),
        updatedAt: parseNullableDateTime(json['updatedAt']),
      );

  MatchmakerUserNote toEntity() => MatchmakerUserNote(
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
