import '../../domain/entities/badge_update_event.dart';
import '../json_parsers.dart';

/// Wire model for the SignalR `BadgeUpdated` payload.
///
/// Deliberately does not judge the values: an unrecognised `tab` is passed
/// through (the contract says to ignore what we do not know, and the cubit
/// already stores such keys where nothing reads them) and a negative `count`
/// is left alone for the cubit to floor. One place owns that policy.
class BadgeUpdateEventModel {
  final String tab;
  final int count;

  const BadgeUpdateEventModel({required this.tab, required this.count});

  factory BadgeUpdateEventModel.fromJson(Map<String, dynamic> json) =>
      BadgeUpdateEventModel(
        tab: parseString(json['tab']),
        count: parseInt(json['count']),
      );

  BadgeUpdateEvent toEntity() => BadgeUpdateEvent(tab: tab, count: count);
}
