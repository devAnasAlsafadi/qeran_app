import '../../domain/entities/community_guidelines.dart';
import '../json_parsers.dart';

/// Wire model for `GET community/guidelines` (contract §4.1):
/// `{ version, lastUpdatedAt, introAr, introEn, sections: [{ id, icon,
/// titleAr, titleEn, bodyAr, bodyEn }] }` — the legal documents' shape plus
/// a version, an intro and an icon name per section.
class CommunityGuidelinesModel {
  final int version;
  final DateTime? lastUpdatedAt;
  final String introAr;
  final String introEn;
  final List<CommunityGuidelineSectionModel> sections;

  const CommunityGuidelinesModel({
    required this.version,
    required this.lastUpdatedAt,
    required this.introAr,
    required this.introEn,
    required this.sections,
  });

  factory CommunityGuidelinesModel.fromJson(Map<String, dynamic> json) =>
      CommunityGuidelinesModel(
        version: parseInt(json['version']),
        lastUpdatedAt: parseNullableDateTime(json['lastUpdatedAt']),
        introAr: parseString(json['introAr']),
        introEn: parseString(json['introEn']),
        sections: parseMapList(json['sections'])
            .map(CommunityGuidelineSectionModel.fromJson)
            .toList(growable: false),
      );

  CommunityGuidelines toEntity() => CommunityGuidelines(
        version: version,
        lastUpdatedAt: lastUpdatedAt,
        introAr: introAr,
        introEn: introEn,
        sections: sections.map((s) => s.toEntity()).toList(growable: false),
      );
}

class CommunityGuidelineSectionModel {
  final int id;
  final String icon;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  const CommunityGuidelineSectionModel({
    required this.id,
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });

  factory CommunityGuidelineSectionModel.fromJson(Map<String, dynamic> json) =>
      CommunityGuidelineSectionModel(
        id: parseInt(json['id']),
        icon: parseString(json['icon']).trim(),
        titleAr: parseString(json['titleAr']),
        titleEn: parseString(json['titleEn']),
        bodyAr: parseString(json['bodyAr']),
        bodyEn: parseString(json['bodyEn']),
      );

  CommunityGuidelineSection toEntity() => CommunityGuidelineSection(
        id: id,
        iconName: icon,
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
      );
}
