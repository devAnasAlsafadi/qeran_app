import 'package:equatable/equatable.dart';

/// A legal document (privacy policy or terms) — a server-computed
/// [lastUpdatedAt] plus ordered bilingual [sections]. Both fields are dynamic:
/// [lastUpdatedAt] is null when there are no sections, [sections] is `[]` (never
/// null). The presentation layer picks the ar/en text by the app locale.
class LegalDocument extends Equatable {
  /// Newest section `updatedAt`, in UTC. Null when there are no sections.
  final DateTime? lastUpdatedAt;
  final List<LegalSection> sections;

  const LegalDocument({required this.lastUpdatedAt, required this.sections});

  bool get isEmpty => sections.isEmpty;

  @override
  List<Object?> get props => [lastUpdatedAt, sections];
}

/// One section of a [LegalDocument]. [bodyAr]/[bodyEn] may contain `\n`
/// newlines and `•` bullets — render verbatim with a soft-wrapping Text.
class LegalSection extends Equatable {
  final int id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final DateTime? updatedAt;

  const LegalSection({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, titleAr, titleEn, bodyAr, bodyEn, updatedAt];
}
