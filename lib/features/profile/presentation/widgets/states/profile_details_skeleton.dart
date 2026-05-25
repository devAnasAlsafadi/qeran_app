import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';

/// First-paint placeholder for the Full Profile Details screen when no
/// seed is available (e.g. chat-tap path). The hero block matches the
/// gallery height so the layout doesn't jump when the real image lands.
class ProfileDetailsSkeleton extends StatelessWidget {
  const ProfileDetailsSkeleton({super.key});

  static const double _heroHeight = 360;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QeranSkeleton.box(height: _heroHeight, radius: 0),
        SizedBox(height: QeranSpacing.s20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QeranSkeleton(width: 180, height: 22),
              SizedBox(height: QeranSpacing.s12),
              QeranSkeleton(height: 14),
              SizedBox(height: QeranSpacing.s8),
              QeranSkeleton(width: 240, height: 14),
              SizedBox(height: QeranSpacing.s24),
              QeranSkeleton(width: 140, height: 22),
              SizedBox(height: QeranSpacing.s12),
              Row(
                children: [
                  QeranSkeleton(width: 70, height: 28),
                  SizedBox(width: QeranSpacing.s8),
                  QeranSkeleton(width: 70, height: 28),
                  SizedBox(width: QeranSpacing.s8),
                  QeranSkeleton(width: 70, height: 28),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
