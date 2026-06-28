import '../../domain/entities/legal_document.dart';
import '../json_parsers.dart';

/// Wire model for the `data` object of `GET /api/privacy-policy` and
/// `GET /api/terms-and-conditions` (same shape):
/// `{ lastUpdatedAt, sections: [{ id, titleAr, titleEn, bodyAr, bodyEn,
/// updatedAt }] }`.
class LegalDocumentModel {
  final DateTime? lastUpdatedAt;
  final List<LegalSectionModel> sections;

  const LegalDocumentModel({
    required this.lastUpdatedAt,
    required this.sections,
  });

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) =>
      LegalDocumentModel(
        lastUpdatedAt: parseNullableDateTime(json['lastUpdatedAt']),
        // `[]` (never null) when absent/odd-shaped — `parseMapList` tolerates it.
        sections: parseMapList(json['sections'])
            .map(LegalSectionModel.fromJson)
            .toList(growable: false),
      );

  LegalDocument toEntity() => LegalDocument(
        lastUpdatedAt: lastUpdatedAt,
        sections: sections.map((s) => s.toEntity()).toList(growable: false),
      );
}

class LegalSectionModel {
  final int id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final DateTime? updatedAt;

  const LegalSectionModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.updatedAt,
  });

  factory LegalSectionModel.fromJson(Map<String, dynamic> json) =>
      LegalSectionModel(
        id: parseInt(json['id']),
        titleAr: parseString(json['titleAr']),
        titleEn: parseString(json['titleEn']),
        bodyAr: parseString(json['bodyAr']),
        bodyEn: parseString(json['bodyEn']),
        updatedAt: parseNullableDateTime(json['updatedAt']),
      );

  LegalSection toEntity() => LegalSection(
        id: id,
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
        updatedAt: updatedAt,
      );
}
