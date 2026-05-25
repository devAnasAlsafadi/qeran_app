import '../../domain/entities/like_requests_data.dart';
import 'like_request_card_model.dart';

class LikeRequestsDataModel {
  final List<LikeRequestCardModel> pending;
  final List<LikeRequestCardModel> archived;
  final bool requiresSubscription;

  const LikeRequestsDataModel({
    required this.pending,
    required this.archived,
    required this.requiresSubscription,
  });

  factory LikeRequestsDataModel.fromJson(Map<String, dynamic> json) {
    return LikeRequestsDataModel(
      pending: _parseList(json['pending']),
      archived: _parseList(json['archived']),
      requiresSubscription: json['requiresSubscription'] as bool? ?? false,
    );
  }

  static List<LikeRequestCardModel> _parseList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LikeRequestCardModel.fromJson)
        .toList(growable: false);
  }

  LikeRequestsData toEntity() => LikeRequestsData(
        pending: pending.map((m) => m.toEntity()).toList(growable: false),
        archived: archived.map((m) => m.toEntity()).toList(growable: false),
        requiresSubscription: requiresSubscription,
      );
}
