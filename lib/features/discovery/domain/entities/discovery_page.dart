import 'package:equatable/equatable.dart';

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

  const DiscoveryPage({
    required this.profiles,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [
        profiles,
        pageNumber,
        pageSize,
        totalCount,
        totalPages,
      ];
}
