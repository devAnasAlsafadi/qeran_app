import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_like_activity.dart';
import 'matchmaker_interest_like_model.dart';

/// Wire model for ActivityPageDto {pending[], archived[], requiresSubscription}.
/// ⚠️ Field names to confirm: pending / archived / requiresSubscription.
class MatchmakerLikeActivityModel {
  final List<MatchmakerInterestLikeModel> pending;
  final List<MatchmakerInterestLikeModel> archived;
  final bool requiresSubscription;

  const MatchmakerLikeActivityModel({
    required this.pending,
    required this.archived,
    required this.requiresSubscription,
  });

  factory MatchmakerLikeActivityModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerLikeActivityModel(
        pending: parseMapList(json['pending'])
            .map(MatchmakerInterestLikeModel.fromJson)
            .toList(growable: false),
        archived: parseMapList(json['archived'])
            .map(MatchmakerInterestLikeModel.fromJson)
            .toList(growable: false),
        requiresSubscription: parseBool(json['requiresSubscription']),
      );

  MatchmakerLikeActivity toEntity() => MatchmakerLikeActivity(
        pending: pending.map((m) => m.toEntity()).toList(growable: false),
        archived: archived.map((m) => m.toEntity()).toList(growable: false),
        requiresSubscription: requiresSubscription,
      );
}
