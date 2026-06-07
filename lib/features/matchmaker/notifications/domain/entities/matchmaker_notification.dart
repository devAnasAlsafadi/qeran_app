import 'package:equatable/equatable.dart';

/// The notification kind from the wire `type` field. Drives the leading icon.
/// Tolerant `unknown` for any future/unrecognised value.
enum MatchmakerNotificationType {
  general,
  chat,
  match,
  profile,
  announcement,
  offer,
  unknown;

  static MatchmakerNotificationType fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'general':
        return MatchmakerNotificationType.general;
      case 'chat':
        return MatchmakerNotificationType.chat;
      case 'match':
        return MatchmakerNotificationType.match;
      case 'profile':
        return MatchmakerNotificationType.profile;
      case 'announcement':
        return MatchmakerNotificationType.announcement;
      case 'offer':
        return MatchmakerNotificationType.offer;
      default:
        return MatchmakerNotificationType.unknown;
    }
  }
}

/// One inbox notification from `GET /api/notifications`. Carries both locale
/// variants of the title/body (the UI picks by `context.locale`), the parsed
/// [data] deep-link payload (the wire `data` is a JSON STRING, decoded in the
/// model), and [createdAt]. No read-state — the backend exposes none.
class MatchmakerNotification extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final MatchmakerNotificationType type;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  const MatchmakerNotification({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  /// Title for [isArabic] (falls back to the other locale when one is empty).
  String title({required bool isArabic}) =>
      _pick(titleAr, titleEn, isArabic: isArabic);

  /// Body for [isArabic] (same fallback rule).
  String body({required bool isArabic}) =>
      _pick(bodyAr, bodyEn, isArabic: isArabic);

  String _pick(String ar, String en, {required bool isArabic}) {
    final primary = isArabic ? ar : en;
    if (primary.isNotEmpty) return primary;
    return isArabic ? en : ar;
  }

  @override
  List<Object?> get props =>
      [id, titleAr, titleEn, bodyAr, bodyEn, type, data, createdAt];
}
