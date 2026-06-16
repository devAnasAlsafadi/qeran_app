import 'package:equatable/equatable.dart';

/// A matchmaker's private note about one compatibility case, from
/// `GET /matchmaker/compatibility-cases/{id}/my-note`. [content] is the note
/// text; the timestamps are nullable (defensive — surfaced as an optional
/// "last edited" caption). A `null` note (not this object) means "no note yet".
class CaseNote extends Equatable {
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CaseNote({
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [content, createdAt, updatedAt];
}
