import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_sheet_handle.dart';

/// The one modal-bottom-sheet presenter for the app — dome top corners, `e3`
/// elevation, a dark-wine scrim, scroll-controlled + safe-area. Pair the
/// [builder]'s content with [QeranBottomSheetScaffold] for consistent chrome
/// (handle + title + circular close + optional pinned footer).
Future<T?> showQeranBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    builder: builder,
  );
}

/// Shared sheet chrome: the paper dome surface, a wine-12 grab handle, a title
/// row with a soft-fill circular close, the scrollable [body], and an optional
/// pinned [footer]. The sheet wraps its content when short and grows to
/// [maxHeightFactor] of the screen when the body is long (the body scrolls).
///
/// **Any sheet with a text field must pass [scrollableBody] `true`.** The
/// keyboard shrinks the available height (via the `viewInsets` padding below),
/// and a fixed `Column` body cannot absorb that — it overflows. See the flag's
/// own doc for why this is opt-in rather than automatic.
class QeranBottomSheetScaffold extends StatelessWidget {
  const QeranBottomSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.onClose,
    this.maxHeightFactor = 0.92,
    this.scrollableBody = false,
  });

  final String title;

  /// The main content. A `Column(mainAxisSize: min)` wraps; a `ListView` (or
  /// any scrollable) fills up to [maxHeightFactor] and scrolls.
  final Widget body;

  /// Wraps [body] in a `SingleChildScrollView` so a fixed-height body SHRINKS
  /// (scrolls) instead of overflowing when the keyboard eats the sheet's
  /// height. Required for every sheet that hosts an input.
  ///
  /// Opt-in, not automatic: bodies that are already scrollable or that use
  /// `Expanded`/`Flexible` internally (e.g. the share picker's `ListView`)
  /// would get unbounded height inside a scroll view and assert.
  final bool scrollableBody;

  /// Optional pinned footer (kept out of the scroll area), e.g. the actions.
  final Widget? footer;

  /// Defaults to popping the sheet.
  final VoidCallback? onClose;

  /// Cap as a fraction of screen height (the body scrolls beyond it).
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: QeranColors.paper,
            borderRadius: QeranRadii.domeTop,
            boxShadow: QeranShadows.e3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const QeranSheetHandle(),
              _TitleRow(
                title: title,
                onClose: onClose ?? () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: scrollableBody
                    ? SingleChildScrollView(child: body)
                    : body,
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s8,
        QeranSpacing.s16,
        QeranSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: QeranTypography.title)),
          QeranSpacing.hs8,
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.softFill,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.close_rounded, size: 20, color: QeranColors.wine),
        ),
      ),
    );
  }
}
