import 'package:equatable/equatable.dart';

/// The matchmaker a profile's owner belongs to, as carried by
/// `GET /api/matchmaker/users/{id}/profile` under `assignedMatchmaker`.
///
/// Null on the profile when nobody is assigned. The server sends this as ONE
/// nested object rather than three flat fields, deliberately — flat copies of
/// the same data in the same response drift apart on the first edit. The
/// explore list is the exception and still sends flat fields; both feed the
/// same button.
///
/// [conversationId] is the server's bonus: when it is non-null the
/// matchmaker↔matchmaker conversation already exists, so opening the chat
/// needs no lookup call. Null until the two have ever spoken.
class AssignedMatchmaker extends Equatable {
  final String id;

  /// Wire field is `displayName`; renamed here so the domain keeps one word
  /// for a person's visible name.
  final String name;

  /// Absolute by the time it reaches here. Frequently null in production —
  /// most matchmakers have not uploaded a photo — so callers must have a
  /// fallback rather than treating it as an error.
  final String? imageUrl;

  final int? conversationId;

  const AssignedMatchmaker({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, conversationId];
}
