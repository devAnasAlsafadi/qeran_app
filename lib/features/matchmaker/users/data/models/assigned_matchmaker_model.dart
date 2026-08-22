import 'package:qeran/core/api/end_points.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/assigned_matchmaker.dart';

/// Wire model for the profile payload's nested `assignedMatchmaker` object.
class AssignedMatchmakerModel {
  final String id;
  final String displayName;
  final String? imageUrl;
  final int? conversationId;

  const AssignedMatchmakerModel({
    required this.id,
    required this.displayName,
    required this.imageUrl,
    required this.conversationId,
  });

  /// Returns null for anything that cannot name a matchmaker: an absent
  /// object, a non-map, or a row with no id. An id-less contact would render
  /// a button that opens a chat with nobody.
  static AssignedMatchmakerModel? fromJson(Object? raw) {
    final map = parseNullableMap(raw);
    if (map == null) return null;
    final id = parseString(map['id']);
    if (id.isEmpty) return null;
    return AssignedMatchmakerModel(
      id: id,
      displayName: parseString(map['displayName']),
      imageUrl: parseNullableString(map['imageUrl']),
      conversationId: parseNullableInt(map['conversationId']),
    );
  }

  /// The wire path is relative and needs the auth header, same as
  /// `profileImageUrl` — absolutised here so the widget layer never has to
  /// know that.
  AssignedMatchmaker toEntity() => AssignedMatchmaker(
    id: id,
    name: displayName,
    imageUrl: (imageUrl == null || imageUrl!.isEmpty)
        ? null
        : EndPoints.absoluteUrl(imageUrl!),
    conversationId: conversationId,
  );
}
