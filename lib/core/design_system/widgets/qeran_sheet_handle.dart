import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';

/// The small centered grab bar at the top of a modal bottom sheet. Shared so
/// every Qeran sheet reads consistently (wine-tinted, pill-shaped).
class QeranSheetHandle extends StatelessWidget {
  const QeranSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: const BoxDecoration(
          color: QeranColors.wine20,
          borderRadius: QeranRadii.pill,
        ),
      ),
    );
  }
}
