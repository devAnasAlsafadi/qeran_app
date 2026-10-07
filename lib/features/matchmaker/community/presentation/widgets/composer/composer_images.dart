import 'package:flutter/material.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'composer_image_tile.dart';

/// Her images in the composer (C5): «صور» with «n / max · اسحبي لتغيير
/// الترتيب» (the hint from two images), then the thumbnails in her order —
/// a long press drags one to a new place (M6) — and «إضافة» while more fit.
class ComposerImages extends StatelessWidget {
  const ComposerImages({
    super.key,
    required this.images,
    required this.maxImages,
    required this.locked,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
  });

  final List<PickedImage> images;
  final int? maxImages;

  /// Publishing: nothing moves or leaves.
  final bool locked;

  /// Null when no more fit.
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;

  /// The image at the first index now sits at the second.
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: images.length, max: maxImages),
          SizedBox(height: composerTileSide, child: _strip()),
        ],
      ),
    );
  }

  Widget _strip() => ReorderableListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
    buildDefaultDragHandles: !locked,
    itemCount: images.length,
    proxyDecorator: (child, _, _) => DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: QeranRadii.controlR,
        boxShadow: QeranShadows.e3,
      ),
      child: child,
    ),
    onReorderItem: onMove,
    itemBuilder: (_, index) => Padding(
      key: ValueKey(images[index].path),
      padding: const EdgeInsetsDirectional.only(end: QeranSpacing.s8),
      child: ComposerImageTile(
        path: images[index].path,
        onRemove: locked ? null : () => onRemove(index),
      ),
    ),
    footer: onAdd == null || locked
        ? null
        : ComposerAddImageTile(onTap: onAdd!),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.max});

  final int count;
  final int? max;

  static const _padding = EdgeInsets.fromLTRB(
    QeranSpacing.s20,
    0,
    QeranSpacing.s20,
    QeranSpacing.s8,
  );

  @override
  Widget build(BuildContext context) {
    final max = this.max;
    return Padding(
      padding: _padding,
      child: Row(
        children: [
          Text(
            LocaleKeys.matchmaker_community_images.t(context),
            style: QeranTypography.label.copyWith(
              color: QeranColors.inkStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (max != null) _count(max),
          // Nothing to reorder with one image.
          if (count > 1) Flexible(child: _hint(context, after: max != null)),
        ],
      ),
    );
  }

  Widget _count(int max) => Text(
    '$count / $max',
    textDirection: TextDirection.ltr,
    style: QeranTypography.numeric.copyWith(
      fontSize: QeranTypography.label.fontSize,
      color: QeranColors.inkMuted,
    ),
  );

  /// «اسحبي لتغيير الترتيب», after a « · » when the count leads it.
  Widget _hint(BuildContext context, {required bool after}) => Text(
    '${after ? ' · ' : ''}'
    '${LocaleKeys.matchmaker_community_reorder_hint.t(context)}',
    style: QeranTypography.label.copyWith(color: QeranColors.inkMuted),
    overflow: TextOverflow.ellipsis,
  );
}
