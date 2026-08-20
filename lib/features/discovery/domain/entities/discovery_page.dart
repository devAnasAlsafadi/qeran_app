import 'package:equatable/equatable.dart';

import 'discovery_empty_reason.dart';
import 'discovery_profile.dart';

class DiscoveryPage extends Equatable {
  final List<DiscoveryProfile> profiles;
  final int pageNumber;
  final int pageSize;
  /// Profiles matching the whole query server-side. Null when the backend did
  /// not report a total — never substitute `profiles.length`, which only
  /// counts what this page loaded.
  final int? totalCount;
  final int totalPages;

  /// Why the deck is empty, when the backend says. Null on any page carrying
  /// profiles, and null from a backend that predates the field — so it is a
  /// hint the UI may use, never a value it may require.
  final DiscoveryEmptyReason? reason;

  const DiscoveryPage({
    required this.profiles,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    this.reason,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [
        profiles,
        pageNumber,
        pageSize,
        totalCount,
        totalPages,
        reason,
      ];
}
