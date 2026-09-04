import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_image.dart';
import '../blocs/photo_view_cubit.dart';
import 'like_blurred_image.dart';
import 'match_photo_pager.dart';
import 'photo_view_access_host.dart';
import 'photo_view_overlay.dart';

part 'match_gallery_sheet_parts.dart';

/// Where the sheet rests while the grid is showing — still reads as a sheet,
/// with the card it was opened from visible behind it.
const double _kRestingSize = 0.7;

/// Where it goes while a photo is open. The pager stays INSIDE the sheet (see
/// [MatchPhotoPager] for why that is not negotiable), so the only way to give
/// a photo the screen is to give it to the host.
const double _kExpandedSize = 0.95;

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

class _MatchGallerySheet extends StatefulWidget {
  final List<MatchImage> images;
  final String? targetUserId;
  const _MatchGallerySheet({required this.images, this.targetUserId});

  @override
  State<_MatchGallerySheet> createState() => _MatchGallerySheetState();
}

class _MatchGallerySheetState extends State<_MatchGallerySheet> {
  /// The photo open in the pager, or null while the grid is showing. The pager
  /// is a LAYER over this sheet rather than a pushed route, which is what keeps
  /// it inside `PhotoViewScope` — see [MatchPhotoPager].
  int? _openIndex;

  /// Drives the sheet's own extent so opening a photo can expand the host.
  /// Only the HEIGHT moves — the pager never leaves this subtree.
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _open(int index) {
    setState(() => _openIndex = index);
    _resize(_kExpandedSize);
  }

  /// Idempotent: the pager also calls this when the viewing window ends, which
  /// can arrive while a close is already animating out.
  void _close() {
    if (_openIndex == null) return;
    setState(() => _openIndex = null);
    _resize(_kRestingSize);
  }

  /// The controller detaches as the sheet is dismissed, and `animateTo`
  /// asserts on a detached one — a window that ends on the way out would
  /// otherwise crash instead of just closing.
  void _resize(double size) {
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      size,
      duration: QeranMotion.gentle,
      curve: QeranCurves.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      expand: false,
      initialChildSize: _kRestingSize,
      minChildSize: 0.4,
      maxChildSize: _kExpandedSize,
      builder: (context, scrollController) {
        // Rebuilt on every extent tick of the resize. The pager sits at a
        // fixed spot in this tree with an unchanging type, so it is UPDATED
        // rather than replaced — its page index and its zoom survive.
        return Stack(
          children: [
            Positioned.fill(
              child: _GalleryGrid(
                images: widget.images,
                targetUserId: widget.targetUserId,
                scrollController: scrollController,
                onOpen: _open,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _openIndex == null,
                child: AnimatedSwitcher(
                  // The route this replaces flew a Hero into place. A layer
                  // cannot fly, so it fades — a hard cut on a photo the member
                  // has one chance to see reads as a glitch.
                  duration: QeranMotion.standard,
                  child: _openIndex == null
                      ? const SizedBox.shrink()
                      : ClipRRect(
                          // Keeps the sheet's domed top instead of painting
                          // square corners over it.
                          borderRadius: QeranRadii.domeTop,
                          child: MatchPhotoPager(
                            images: widget.images,
                            initialIndex: _openIndex!,
                            onClose: _close,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
