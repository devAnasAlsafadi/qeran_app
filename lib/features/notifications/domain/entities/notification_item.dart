import 'package:equatable/equatable.dart';

import 'notification_action.dart';
import 'notification_type.dart';

/// One inbox notification from `GET /api/notifications`.
///
/// Carries both locale variants of the title/body (the UI picks by the active
/// locale, with a fallback to the other when one is empty), the typed [type],
/// and the parsed [data] deep-link payload (the wire `data` is a JSON STRING,
/// decoded in the model). [action] is derived from `data.action` and
/// disambiguates the overloaded `Match` type. No read-state — the backend
/// exposes none.
class NotificationItem extends Equatable {
  final int id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  /// The specific event for an overloaded type, read from `data.action`.
  NotificationAction get action =>
      NotificationAction.fromWire(data['action']?.toString());

  /// Title for the active locale (falls back to the other when one is empty).
  String title({required bool isArabic}) =>
      _pick(titleAr, titleEn, isArabic: isArabic);

  /// Body for the active locale (same fallback rule).
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
