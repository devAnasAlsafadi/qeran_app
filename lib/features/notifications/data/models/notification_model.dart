import 'dart:convert';

import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_type.dart';
import '../json_parsers.dart';

/// Wire model for one `GET /api/notifications` row. The wire `data` is a JSON
/// STRING (unlike FCM's flat-string map) — [_decodeData] `jsonDecode`s it and
/// tolerates a null/blank/malformed value by yielding an empty map, so a bad
/// payload never collapses the row.
class NotificationModel {
  final int id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String? type;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: parseInt(json['id']),
        titleAr: parseString(json['titleAr']),
        titleEn: parseString(json['titleEn']),
        bodyAr: parseString(json['bodyAr']),
        bodyEn: parseString(json['bodyEn']),
        type: parseNullableString(json['type']),
        data: _decodeData(json['data']),
        createdAt: parseNullableDateTime(json['createdAt']),
      );

  /// Decodes the JSON-string `data` field. Already-a-map (FCM / future shape) is
  /// passed through; null/blank/non-object/malformed → empty map.
  static Map<String, dynamic> _decodeData(Object? raw) {
    if (raw is Map) return parseNullableMap(raw) ?? const {};
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return parseNullableMap(jsonDecode(raw)) ?? const {};
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }

  NotificationItem toEntity() => NotificationItem(
        id: id,
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
        type: NotificationType.fromWire(type),
        data: data,
        createdAt: createdAt,
      );
}
