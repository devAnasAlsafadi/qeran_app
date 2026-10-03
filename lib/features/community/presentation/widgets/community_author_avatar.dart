import 'package:flutter/material.dart';

import '../../../../core/design_system/widgets/qeran_monogram.dart';
import '../../domain/entities/community_author.dart';
import 'community_network_image.dart';

/// Who wrote it, as a picture (A19, D10). A matchmaker: her photo inside the
/// gold ring, or her wine-and-gold monogram when she has none — and while it
/// loads, or if it fails. Her photo comes from Community's own avatar path,
/// never blurred, so it doesn't go through the profile-photo widgets. A
/// member has no photo in Community: a plain monogram.
class CommunityAuthorAvatar extends StatelessWidget {
  const CommunityAuthorAvatar({
    super.key,
    required this.author,
    this.size = 44,
  });

  final CommunityAuthor author;
  final double size;

  /// The gold ring the photo sits inside — the monogram's own.
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    if (!author.isMatchmaker) {
      return QeranMonogram(
        name: author.displayName,
        size: size,
        tone: QeranMonogramTone.plain,
      );
    }
    final monogram = QeranMonogram(name: author.displayName, size: size);
    final photo = author.profileImageUrl?.trim() ?? '';
    if (photo.isEmpty) return monogram;
    // The monogram stays underneath: its ring frames the photo, and it shows
    // through while the photo loads or if it fails.
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          monogram,
          Padding(
            padding: const EdgeInsets.all(_ring),
            child: ClipOval(
              child: CommunityNetworkImage(
                photo,
                placeholder: const SizedBox.shrink(),
                fallback: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
