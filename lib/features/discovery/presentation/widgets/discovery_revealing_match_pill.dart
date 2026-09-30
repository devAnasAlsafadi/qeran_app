import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/features/profile/presentation/widgets/full_profile_image_overlays.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The compatibility pill, revealed by [reveal].
///
/// It occupies NO height at rest — name and chips sit directly against each
/// other — and grows into place as [reveal] runs 0 → 1. Because the identity
/// block is anchored to the BOTTOM of the photo, that growth pushes the name
/// upward and the pill slides into the room the name just left, which is the
/// whole point: no reserved gap waiting to be filled.
///
/// A null [reveal] renders the pill outright (any caller that isn't the merged
/// scroll).
class DiscoveryRevealingMatchPill extends StatelessWidget {
  const DiscoveryRevealingMatchPill({
    super.key,
    required this.percent,
    required this.reveal,
    required this.gap,
  });

  final double percent;
  final ValueListenable<double>? reveal;

  /// Space between the name and the pill. Part of what collapses, so at rest
  /// it costs nothing either.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final pill = ProfileMatchPill(
      label: context.tr(
        LocaleKeys.profile_compatibility_label,
        namedArgs: {'percent': '${percent.round()}'},
      ),
    );
    final source = reveal;
    final block = Padding(
      padding: EdgeInsets.only(top: gap),
      child: Align(alignment: AlignmentDirectional.centerStart, child: pill),
    );
    if (source == null) return block;
    return ValueListenableBuilder<double>(
      valueListenable: source,
      builder: (context, value, child) {
        final t = value.clamp(0.0, 1.0);
        if (t == 0) return const SizedBox.shrink();
        // heightFactor scales the box; bottom alignment means the pill emerges
        // from under the chips rather than being squashed. Opacity on top so
        // it fades rather than wipes.
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            heightFactor: t,
            child: Opacity(opacity: t, child: child),
          ),
        );
      },
      child: block,
    );
  }
}
