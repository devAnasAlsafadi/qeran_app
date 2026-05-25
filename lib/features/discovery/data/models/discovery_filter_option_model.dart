import '../../domain/entities/discovery_filter_option.dart';

class DiscoveryFilterOptionModel {
  final String value;
  final String display;

  const DiscoveryFilterOptionModel({
    required this.value,
    required this.display,
  });

  factory DiscoveryFilterOptionModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryFilterOptionModel(
      value: json['value']?.toString() ?? '',
      display: json['display']?.toString() ?? '',
    );
  }

  DiscoveryFilterOption toEntity() => DiscoveryFilterOption(
        value: value,
        display: display,
      );
}
