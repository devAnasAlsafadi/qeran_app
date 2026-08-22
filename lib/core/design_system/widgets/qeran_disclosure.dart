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
/// Expansion is self-managed. A caller that needs several of these to
/// coordinate — one open at a time — will want an optional controlled mode,
/// which is a pure addition to this constructor.
class QeranDisclosure extends StatefulWidget {
  const QeranDisclosure({
    super.key,
    required this.summary,
    required this.child,
    this.initiallyExpanded = false,
  });

  /// Always visible, beside the chevron. Sized by its own content.
  final Widget summary;

  /// Revealed when open. Built only while open, so a long list of these costs
  /// nothing for the ones nobody has touched.
  final Widget child;

  final bool initiallyExpanded;

  @override
  State<QeranDisclosure> createState() => _QeranDisclosureState();
}

class _QeranDisclosureState extends State<QeranDisclosure> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

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
