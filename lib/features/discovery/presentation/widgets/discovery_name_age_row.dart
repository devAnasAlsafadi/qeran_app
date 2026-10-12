import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Name and age on the photo, in paper over its bottom gradient — with
/// [trailing], the card's ⋮, at the line's end.
class DiscoveryNameAgeRow extends StatelessWidget {
  final String name;
  final int age;
  final Widget? trailing;

  const DiscoveryNameAgeRow({
    super.key,
    required this.name,
    required this.age,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '$name $age',
      style: QeranTypography.headline.copyWith(
        color: QeranColors.paper,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final trailing = this.trailing;
    if (trailing == null) return text;
    return Row(
      children: [
        Expanded(child: text),
        QeranSpacing.hs8,
        trailing,
      ],
    );
  }
}
