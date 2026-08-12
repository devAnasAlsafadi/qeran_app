import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/profile/presentation/screens/photo_manager/widgets/photo_preview_screen.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_image.dart';
import '../blocs/photo_view_cubit.dart';
import '../blocs/photo_view_state.dart';
import 'like_blurred_image.dart';
import 'photo_view_access_host.dart';
import 'photo_view_overlay.dart';

/// Gallery shown when the user taps the avatar on a stage-1 Match card.
/// Renders the full server-ordered image list with the per-image blur flag
/// honored, and lets the user open any photo they can already see clearly
/// full-screen (Hero + pinch-zoom).
///
/// [targetUserId] enables a Report action in the header (UGC safety) — the
/// photos are the sensitive content here. Omit it to hide the action.
Future<void> showMatchGallerySheet(
  BuildContext context, {
  required List<MatchImage> images,
  String? targetUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    useSafeArea: true,
    builder: (_) {
      final sheet = _MatchGallerySheet(
        images: images,
        targetUserId: targetUserId,
      );
      if (targetUserId == null) return sheet;
      return BlocProvider<PhotoViewCubit>(
        create: (_) => sl<PhotoViewCubit>(param1: targetUserId)..load(),
        child: PhotoViewAccessHost(child: sheet),
      );
    },
  );
}

class _MatchGallerySheet extends StatelessWidget {
  final List<MatchImage> images;
  final String? targetUserId;
  const _MatchGallerySheet({required this.images, this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: QeranColors.paper,
            borderRadius: QeranRadii.domeTop,
          ),
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s16,
            QeranSpacing.s12,
            QeranSpacing.s16,
            QeranSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: QeranSpacing.s12),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      LocaleKeys.likes_matches_gallery_title.t(context),
                      textAlign: TextAlign.center,
                      style: QeranTypography.title.copyWith(
                        color: QeranColors.wine,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: targetUserId == null
                        ? null
                        : IconButton(
                            tooltip: LocaleKeys.report_title.t(context),
                            icon: const Icon(
                              Icons.flag_outlined,
                              color: QeranColors.wine,
                              size: 22,
                            ),
                            onPressed: () => showReportSheet(
                              context,
                              targetUserId: targetUserId,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: QeranSpacing.s12),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(top: QeranSpacing.s8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: QeranSpacing.s12,
                              crossAxisSpacing: QeranSpacing.s12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: images.length,
                        itemBuilder: (context, index) =>
                            _GalleryTile(image: images[index]),
                      ),
                    ),
                    const PhotoViewOverlay(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: QeranColors.wine.withValues(alpha: 0.30),
          borderRadius: QeranRadii.pill,
        ),
      ),
    );
  }
}


/// One photo in the gallery grid.
///
/// Tappable exactly when the photo is already being shown CLEAR — during the
/// open 60-second window. A blurred tile (locked, or the window spent) ignores
/// taps entirely rather than offering a zoom of a redacted image.
class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.image});

  final MatchImage image;

  @override
  Widget build(BuildContext context) {
    final access = PhotoViewScope.maybeOf(context);
    final blurred = access?.effectiveBlur(image.isBlurred) ?? image.isBlurred;
    final tile = LikeBlurredImage(
      url: image.url,
      blur: image.isBlurred,
      blurredUrl: image.blurredUrl,
      blurredThumbnailUrl: image.blurredThumbnailUrl,
      size: null,
      shape: BoxShape.rectangle,
      borderRadius: QeranRadii.cardR,
    );
    if (blurred || image.url.isEmpty) return tile;
    return GestureDetector(
      onTap: () => _openPreview(context),
      child: Hero(tag: serverPhotoHeroTag(image.id), child: tile),
    );
  }

  void _openPreview(BuildContext context) {
    // The preview is pushed ABOVE this scope, so it cannot inherit the policy.
    // It gets the cubit by value — to close itself the moment the window ends
    // — and `memoryOnly` so the clear bytes never reach the disk cache.
    PhotoViewCubit? cubit;
    try {
      cubit = context.read<PhotoViewCubit>();
    } catch (_) {
      cubit = null;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          final preview = PhotoPreviewScreen.network(
            imageUrl: image.url,
            imageId: image.id,
            memoryOnly: cubit != null,
          );
          if (cubit == null) return preview;
          return BlocProvider<PhotoViewCubit>.value(
            value: cubit,
            child: _PopWhenWindowCloses(child: preview),
          );
        },
      ),
    );
  }
}

/// Pops the full-screen preview as soon as the viewing window ends, so an open
/// zoom cannot outlive the 60 seconds it was granted.
class _PopWhenWindowCloses extends StatelessWidget {
  const _PopWhenWindowCloses({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhotoViewCubit, PhotoViewState>(
      listenWhen: (previous, current) => current.phase != PhotoViewPhase.viewing,
      listener: (context, _) => Navigator.of(context).maybePop(),
      child: child,
    );
  }
}
