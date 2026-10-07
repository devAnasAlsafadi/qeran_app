import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// The composer's toolbar, which sits on the keyboard (C1, C2): «صور» for
/// now; the video button and the either-or hint come with video.
class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({super.key, required this.onImages});

  /// Null when no more images fit: the button dims to 40 % (C5).
  final VoidCallback? onImages;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        border: Border(top: BorderSide(color: QeranColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.photo_library_rounded,
                  label: LocaleKeys.matchmaker_community_images.t(context),
                  onTap: onImages,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft-filled tool, wine icon and label, 48 high.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: QeranColors.softFill,
        borderRadius: QeranRadii.controlR,
        child: InkWell(
          onTap: onTap,
          borderRadius: QeranRadii.controlR,
          child: SizedBox(height: 48, child: _content()),
        ),
      ),
    );
  }

  Widget _content() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: QeranColors.wine),
        const SizedBox(width: QeranSpacing.s6),
        Text(
          label,
          style: QeranTypography.label.copyWith(
            color: QeranColors.wine,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
