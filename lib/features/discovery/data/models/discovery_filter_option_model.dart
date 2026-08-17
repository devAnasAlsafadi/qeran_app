import '../../domain/entities/discovery_filter_option.dart';
import '../json_parsers.dart';

class DiscoveryFilterOptionModel {
  final String value;
  final String display;

  /// Dashboard-controlled ordering weight. Null while the backend rollout is
  /// in flight — absence is expected, not an error.
  final int? displayPriority;

  const DiscoveryFilterOptionModel({
    required this.value,
    required this.display,
    this.displayPriority,
  });

  factory DiscoveryFilterOptionModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryFilterOptionModel(
      value: json['value']?.toString() ?? '',
      display: json['display']?.toString() ?? '',
      displayPriority: parseNullableInt(json['displayPriority']),
    );
  }

  DiscoveryFilterOption toEntity() => DiscoveryFilterOption(
        value: value,
        display: display,
        displayPriority: displayPriority,
      );
}
