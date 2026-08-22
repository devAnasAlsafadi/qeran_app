import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';

/// A tap-to-open section: an always-visible [summary] row with a chevron, and
/// [child] revealed beneath it.
///
/// Material's `ExpansionTile` is the obvious reach and the wrong one — it
/// brings its own dividers, icon tint and tile metrics, none of which are ours,
/// and the app ships no Material widgets. This is the same affordance built on
/// tokens.
///
/// The caller owns padding and background; this contributes only the tap
/// target and the reveal, so it drops into a card without fighting its rhythm.
///
/// Expansion works either way. Leave [expanded] null and the widget keeps its
/// own state; pass it and the caller owns it — which is what a set of these
/// needs when only one may be open at a time.
class QeranDisclosure extends StatefulWidget {
  const QeranDisclosure({
    super.key,
    required this.summary,
    required this.child,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpandedChanged,
  });

  /// Always visible, beside the chevron. Sized by its own content.
  final Widget summary;

  /// Revealed when open. Built only while open, so a long list of these costs
  /// nothing for the ones nobody has touched.
  final Widget child;

  /// Only consulted when [expanded] is null.
  final bool initiallyExpanded;

  /// Non-null hands control to the caller: the row draws this, and a tap
  /// reports the requested value through [onExpandedChanged] rather than
  /// changing anything here. Without a listener that makes the row inert, so
  /// pass both or neither.
  final bool? expanded;

  /// The value a tap is asking for — already flipped, so the caller can store
  /// it directly.
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<QeranDisclosure> createState() => _QeranDisclosureState();
}

class _QeranDisclosureState extends State<QeranDisclosure> {
  late bool _selfExpanded = widget.initiallyExpanded;

  bool get _expanded => widget.expanded ?? _selfExpanded;

  void _toggle() {
    final next = !_expanded;
    widget.onExpandedChanged?.call(next);
    // Controlled: the caller decides, and the rebuild arrives with the new
    // value. Touching local state here would let the two disagree for a frame.
    if (widget.expanded == null) setState(() => _selfExpanded = next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: QeranRadii.controlR,
              onTap: _toggle,
              splashColor: QeranColors.wine12,
              highlightColor: QeranColors.wine08,
              child: ConstrainedBox(
                // Keeps the row a real tap target even when the summary is a
                // single short line.
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Expanded(child: widget.summary),
                    QeranSpacing.hs8,
                    AnimatedRotation(
                      duration: QeranMotion.fast,
                      curve: QeranCurves.standard,
                      // Half a turn: the chevron points down closed, up open.
                      // Vertical, so nothing to mirror by locale.
                      turns: _expanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: QeranColors.wine,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: QeranMotion.standard,
          curve: QeranCurves.standard,
          alignment: AlignmentDirectional.topStart,
          child: _expanded
              ? widget.child
              // Full-width so opening changes height only, never width.
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
