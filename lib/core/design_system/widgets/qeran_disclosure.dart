import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

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
    this.hint,
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

  /// A few words naming what opening this reveals, shown beside [summary]
  /// while closed and dropped once open.
  ///
  /// A chevron alone is easy to read as decoration, especially on a row whose
  /// summary looks like the status text around it. The hint says outright
  /// that there is something behind the row — and having said it once, it
  /// stops: a member who has opened one of these does not need telling again,
  /// and the expanded row is busy enough.
  ///
  /// The caller supplies the WORDS, never the styling. Whatever this reveals,
  /// the hint reads the same everywhere.
  final String? hint;

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
                    // One Expanded around both, rather than flexing each of
                    // them beside a Spacer. A Row splits free width by flex
                    // factor, so summary + hint + Spacer capped the summary at
                    // a THIRD of the row while two thirds sat empty — and a
                    // label that fitted on one line while open wrapped to two
                    // the moment the hint appeared beside it.
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(child: widget.summary),
                          if (!_expanded && widget.hint != null) ...[
                            QeranSpacing.hs8,
                            // Unflexed on purpose: the hint is a few fixed
                            // words, the summary is the part worth reading, so
                            // the summary is what yields when space is tight.
                            _Hint(text: widget.hint!),
                          ],
                        ],
                      ),
                    ),
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

/// Subordinate by weight, but gold rather than muted ink: in this system gold
/// is what "you can act on this" looks like on a light surface, and a hint
/// whose whole job is to invite a tap should borrow that rather than the
/// vocabulary of metadata.
class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      // Separator and hint share one style so the dot recedes with the words
      // instead of punctuating the summary.
      '· $text',
      textAlign: TextAlign.start,
      style: QeranTypography.label.copyWith(
        color: QeranColors.goldDeep,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
