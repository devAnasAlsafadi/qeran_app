import 'package:qeran/core/data/display_name.dart';

import '../../domain/entities/community_author.dart';
import '../json_parsers.dart';

/// Wire model for an Author (contract §2.1):
/// `{ id, displayName, isMatchmaker, profileImageUrl }`.
class CommunityAuthorModel {
  final String id;
  final String displayName;
  final bool isMatchmaker;
  final String? profileImageUrl;

  const CommunityAuthorModel({
    required this.id,
    required this.displayName,
    required this.isMatchmaker,
    required this.profileImageUrl,
  });

  factory CommunityAuthorModel.fromJson(Map<String, dynamic> json) {
    final image = parseNullableString(json['profileImageUrl'])?.trim();
    return CommunityAuthorModel(
      id: parseString(json['id']),
      // Never `realName` — `parseDisplayName` doesn't consult it.
      displayName: parseDisplayName(json),
      isMatchmaker: parseBool(json['isMatchmaker']),
      profileImageUrl: (image == null || image.isEmpty) ? null : image,
    );
  }

  CommunityAuthor toEntity() => CommunityAuthor(
        id: id,
        displayName: displayName,
        isMatchmaker: isMatchmaker,
        profileImageUrl: profileImageUrl,
      );
}
