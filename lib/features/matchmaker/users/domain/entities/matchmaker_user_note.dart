import 'package:equatable/equatable.dart';

/// A matchmaker's private note about one user, from
/// `GET /matchmaker/users/{id}/note`. [content] is the note text; the
/// timestamps are nullable (defensive — surfaced as an optional caption). A
/// `null` note (not this object) means "no note yet".
class MatchmakerUserNote extends Equatable {
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MatchmakerUserNote({
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [content, createdAt, updatedAt];
}
