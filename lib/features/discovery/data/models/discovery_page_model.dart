import '../../domain/entities/discovery_page.dart';
import 'discovery_profile_model.dart';

class DiscoveryPageModel {
  final List<DiscoveryProfileModel> profiles;
  final int pageNumber;
  final int pageSize;
  /// Nullable for symmetry with the matchmaker's explore page (D9): absent and
  /// zero are different answers. `?? 0` used to conflate them, so a payload
  /// that omitted the field looked like a genuine "no matches".
  final int? totalCount;
  final int totalPages;

  const DiscoveryPageModel({
    required this.profiles,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  /// Consumes the inner `data` envelope produced by `ApiResponse.fromJson`.
  /// The wire shape is:
  ///   { "data": [...], "pageNumber": ..., "pageSize": ...,
  ///     "totalCount": ..., "totalPages": ... }
  factory DiscoveryPageModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryPageModel(
      profiles: (json['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DiscoveryProfileModel.fromJson)
          .toList(),
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      totalCount: json['totalCount'] as int?,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  DiscoveryPage toEntity() => DiscoveryPage(
        profiles: profiles.map((p) => p.toEntity()).toList(),
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
      );
}
