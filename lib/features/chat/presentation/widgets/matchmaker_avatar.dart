import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';

/// The matchmaker's avatar — her real photo (unblurred; the parties are
/// already connected) inside a gold ring, falling back to the wine+gold
/// monogram when there's no photo.
///
/// [size] is the monogram's diameter; the photo sits 2 pt inside the ring, so
/// it is 4 pt smaller.
class MatchmakerAvatar extends StatelessWidget {
  const MatchmakerAvatar({
    super.key,
    required this.url,
    required this.name,
    this.size = 44,
  });

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return QeranMonogram(name: name, size: size, borderWidth: 1.2);
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.2),
      ),
      child: LikeBlurredImage(
        url: url,
        blur: false,
        size: size - 4,
        fallbackIcon: Icons.person_rounded,
      ),
    );
  }
}
