import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';

/// Two small circular avatars overlapped to read as a matched pair. The
/// trailing avatar layers over the leading one; each wears a 2px [paper]
/// ring so two identical cream fallbacks stay visually distinct instead of
/// merging into one blob. Directional: in RTL the first avatar sits at the
/// right and the second overlaps to its left, on top — no manual swap.
class CasePairedAvatars extends StatelessWidget {
  const CasePairedAvatars({
    super.key,
    required this.firstUrl,
    required this.secondUrl,
    this.firstName,
    this.secondName,
    this.avatarSize = 52,
    this.ringWidth = 2,
    this.overlap = 0.36,
  });

  final String? firstUrl;
  final String? secondUrl;

  /// Names for the wine+gold monogram fallback when an avatar has no photo
  /// (absent → the plain person placeholder).
  final String? firstName;
  final String? secondName;

  final double avatarSize;
  final double ringWidth;

  /// Fraction of an avatar's outer diameter the second one overlaps the first.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final outer = avatarSize + ringWidth * 2;
    final offset = outer * (1 - overlap);
    return SizedBox(
      width: outer + offset,
      height: outer,
      child: Stack(
        children: [
          PositionedDirectional(start: 0, child: _ringed(firstUrl, firstName)),
          PositionedDirectional(
            start: offset,
            child: _ringed(secondUrl, secondName),
          ),
        ],
      ),
    );
  }

  Widget _ringed(String? url, String? name) {
    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.paper,
      ),
      child: MatchmakerUserAvatar(
        url: url,
        size: avatarSize,
        monogramName: name,
      ),
    );
  }
}
