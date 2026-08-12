import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';

/// Uniform card scaffold shared by all three interest card types (active
/// match, incoming/sent like, archived item). It owns the avatar, the lock
/// redaction, the name, the chips + facts rows, the trailing chevron, the
/// surface, and the locked dim — each caller only decides which chips/facts to
/// feed and where a tap goes.
///
/// Variants:
/// * **active** (`archived` false, `locked` false) — paper card + gold accent
///   bar; tappable; trailing chevron.
/// * **archive** (`archived` true) — muted flat card (cream canvas + wine-08
///   border, no shadow); tappable; trailing chevron.
/// * **locked** (`locked` true, overrides the surface) — privacy state: the
///   avatar is blurred with a wine scrim + lock glyph, the name is redacted,
///   chips + facts are hidden, the whole card is dimmed (.72) and
///   non-interactive (no tap, no chevron). Reads as redacted at a glance.
class MatchmakerInterestCard extends StatelessWidget {
  const MatchmakerInterestCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.locked,
    this.archived = false,
    this.chips = const [],
    this.facts,
    this.onTap,
  });

  final String? imageUrl;
  final String name;
  final bool locked;
  final bool archived;
  final List<Widget> chips;
  final Widget? facts;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const margin = EdgeInsets.only(bottom: QeranSpacing.s12);
    const padding = EdgeInsets.all(QeranSpacing.s12);
    // Locked cards are never interactive, whatever [onTap] the caller passed.
    final tap = locked ? null : onTap;

    final card = archived
        ? QeranCard.flat(
            background: QeranColors.creamCanvas,
            margin: margin,
            padding: padding,
            onTap: tap,
            child: _body(context),
          )
        : QeranCard(
            margin: margin,
            padding: padding,
            onTap: tap,
            child: _body(context),
          );

    return locked ? Opacity(opacity: 0.72, child: card) : card;
  }

  Widget _body(BuildContext context) {
    final showChevron = !locked && onTap != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(imageUrl: imageUrl, name: name, locked: locked),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locked
                    ? LocaleKeys.matchmaker_interests_locked_name.t(context)
                    : name,
                style: QeranTypography.subtitle.copyWith(
                  color: locked ? QeranColors.inkMuted : QeranColors.inkStrong,
                ),
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!locked && facts != null) ...[QeranSpacing.vs8, facts!],
              // Status/timer belong beneath the person's facts, matching the
              // original information hierarchy used by matchmakers.
              if (!locked && chips.isNotEmpty) ...[
                QeranSpacing.vs8,
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: QeranSpacing.s8,
                  runSpacing: QeranSpacing.s4,
                  children: chips,
                ),
              ],
            ],
          ),
        ),
        if (showChevron) ...[QeranSpacing.hs8, const _TrailingChevron()],
      ],
    );
  }
}

/// 56px circular avatar. When [locked] it blurs the photo (client-side opt-in
/// on [MatchmakerUserAvatar]) and stacks a wine scrim + a centered lock glyph;
/// the monogram fallback is dropped when locked so initials never leak.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.name,
    required this.locked,
  });

  final String? imageUrl;
  final String name;
  final bool locked;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final avatar = MatchmakerUserAvatar(
      url: imageUrl,
      size: _size,
      blur: locked,
      monogramName: locked ? null : name,
    );
    if (!locked) return avatar;
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          avatar,
          const ClipOval(
            child: SizedBox(
              width: _size,
              height: _size,
              child: ColoredBox(color: QeranColors.overlayTintDark),
            ),
          ),
          const Icon(Icons.lock_rounded, color: QeranColors.paper, size: 22),
        ],
      ),
    );
  }
}

/// Trailing disclosure chevron. Uses the same primitive as the app-bar back
/// button: `chevron_left_rounded` mirrors under the ambient Directionality
/// (points toward the leading edge in both LTR and RTL). No manual isRtl swap
/// — that plus the framework's auto-mirror would double-flip.
class _TrailingChevron extends StatelessWidget {
  const _TrailingChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right_rounded,
      color: QeranColors.wine40,
      size: 22,
    );
  }
}
