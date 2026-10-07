import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_state.dart';

/// The composer's toolbar, which sits on the keyboard (C1, C2): «صور», and
/// «فيديو» while the server offers video (BA-A4), each dimmed to 40 % when
/// it can't add (C5, C6, D11), with the hint that says why at the end.
class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({
    super.key,
    required this.draft,
    required this.onImages,
    required this.onVideo,
  });

  final PostDraftState draft;
  final VoidCallback onImages;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    final hint = _hint(draft);
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
                ..._buttons(context),
                const SizedBox(width: QeranSpacing.s8),
                Expanded(child: hint == null ? const SizedBox() : _Hint(hint)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buttons(BuildContext context) => [
    _ToolButton(
      icon: Icons.photo_library_rounded,
      label: LocaleKeys.matchmaker_community_images.t(context),
      onTap: draft.canAddImages ? onImages : null,
    ),
    if (draft.videoOffered) ...[
      const SizedBox(width: QeranSpacing.s8),
      _ToolButton(
        icon: Icons.videocam_rounded,
        label: LocaleKeys.matchmaker_community_video.t(context),
        onTap: draft.canAddVideo ? onVideo : null,
      ),
    ],
  ];

  /// Images only for now (BA-A4, A5); one or the other when both are there
  /// (D11). Nothing while the limits haven't been read: nothing is known.
  static String? _hint(PostDraftState draft) {
    if (draft.config == null) return null;
    if (!draft.videoOffered) return LocaleKeys.matchmaker_community_images_only;
    if (draft.images.isNotEmpty) {
      return LocaleKeys.matchmaker_community_hint_no_video_with_images;
    }
    if (draft.video != null) {
      return LocaleKeys.matchmaker_community_hint_no_images_with_video;
    }
    return LocaleKeys.matchmaker_community_hint_either;
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.keyName);

  final String keyName;

  @override
  Widget build(BuildContext context) => Text(
    keyName.t(context),
    textAlign: TextAlign.end,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: QeranTypography.caption.copyWith(
      color: QeranColors.inkMuted,
      fontWeight: FontWeight.w600,
    ),
  );
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
