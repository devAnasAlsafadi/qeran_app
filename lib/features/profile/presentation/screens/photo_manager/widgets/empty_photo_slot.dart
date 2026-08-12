import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

import 'dashed_rect_painter.dart';
import 'photo_primary_badge.dart';

class EmptyPhotoSlot extends StatelessWidget {
  final bool isUploading;
  final int index;
  final VoidCallback onAddTap;

  const EmptyPhotoSlot({
    super.key,
    required this.isUploading,
    required this.index,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onAddTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DashedRectPainter(
                color: QeranColors.wine,
                strokeWidth: 1.5,
                gap: 5.0,
              ),
              child: const Center(
                child: Icon(Icons.add_rounded, color: QeranColors.wine, size: 28),
              ),
            ),
          ),
          if (index == 0)
            const PositionedDirectional(
              bottom: 0,
              start: 0,
              child: PhotoPrimaryBadge(),
            ),
        ],
      ),
    );
  }
}
