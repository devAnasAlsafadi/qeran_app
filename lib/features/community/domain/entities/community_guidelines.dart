import 'package:equatable/equatable.dart';

/// The Community guidelines (contract §4.1) — the server's text (D39), the
/// member or the matchmaker version by token. Accepting sends [version] back;
/// a stale one is refused, and the screen fetches again.
class CommunityGuidelines extends Equatable {
  final int version;
  final DateTime? lastUpdatedAt;
  final String introAr;
  final String introEn;
  final List<CommunityGuidelineSection> sections;

  const CommunityGuidelines({
    required this.version,
    this.lastUpdatedAt,
    required this.introAr,
    required this.introEn,
    required this.sections,
  });

  @override
  List<Object?> get props => [version, lastUpdatedAt, introAr, introEn, sections];
}

/// One rule. [iconName] is a Material Symbols name the client can change from
/// the admin panel (`block`, `phone_disabled`…), so the app maps it with a
/// fallback rather than trusting a fixed list.
class CommunityGuidelineSection extends Equatable {
  final int id;
  final String iconName;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  const CommunityGuidelineSection({
    required this.id,
    required this.iconName,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });

  @override
  List<Object?> get props => [id, iconName, titleAr, titleEn, bodyAr, bodyEn];
}
