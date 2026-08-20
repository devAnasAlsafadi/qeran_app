import '../../domain/entities/discovery_empty_reason.dart';
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

  /// `data.reason` — absent on every page that carries profiles, and absent
  /// entirely from a backend predating the field. Parsed leniently so neither
  /// case, nor a reason this build has never heard of, can break the page.
  final DiscoveryEmptyReason? reason;

  const DiscoveryPageModel({
    required this.profiles,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    this.reason,
  });

  /// Consumes the inner `data` envelope produced by `ApiResponse.fromJson`.
  /// The wire shape is:
  ///   { "data": [...], "pageNumber": ..., "pageSize": ...,
  ///     "totalCount": ..., "totalPages": ..., "reason": "SEEN_ALL" }
  ///
  /// `reason` sits INSIDE this paged object, beside `totalCount` — not on the
  /// outer envelope, which `ApiResponse.fromJson` strips before this runs.
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
      // Not a cast: the field may be missing, null, or a name added after this
      // build shipped. All three have to survive.
      reason: DiscoveryEmptyReason.fromWire(json['reason']),
    );
  }

  DiscoveryPage toEntity() => DiscoveryPage(
        profiles: profiles.map((p) => p.toEntity()).toList(),
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
        reason: reason,
      );
}
