import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Name and age on the photo, in paper over its bottom gradient.
class DiscoveryNameAgeRow extends StatelessWidget {
  final String name;
  final int age;

  const DiscoveryNameAgeRow({super.key, required this.name, required this.age});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$name $age',
      style: QeranTypography.headline.copyWith(
        color: QeranColors.paper,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
