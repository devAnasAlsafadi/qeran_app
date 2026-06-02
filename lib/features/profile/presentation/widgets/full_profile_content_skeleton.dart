import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';

/// Shimmer placeholder for the profile content below the image hero,
/// shown while the full profile (sections + share CTA) loads — so the
/// user never sees a bare button over empty space.
class FullProfileContentSkeleton extends StatelessWidget {
  const FullProfileContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: const [
        // Main sheet placeholder (نبذة عني area), attached to the image.
        DecoratedBox(
          decoration: BoxDecoration(
            color: QeranColors.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(QeranRadii.panel),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              QeranSpacing.s20,
              QeranSpacing.s24,
              QeranSpacing.s20,
              QeranSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QeranSkeleton(width: 120, height: 18),
                SizedBox(height: QeranSpacing.s16),
                QeranSkeleton(height: 12),
                SizedBox(height: QeranSpacing.s8),
                QeranSkeleton(width: 220, height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s20,
            QeranSpacing.s16,
            QeranSpacing.s20,
            QeranSpacing.s32,
          ),
          child: Column(
            children: [
              QeranSkeleton.box(height: 120),
              SizedBox(height: QeranSpacing.s16),
              QeranSkeleton.box(height: 120),
            ],
          ),
        ),
      ],
    );
  }
}
