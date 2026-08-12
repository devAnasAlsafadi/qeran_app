import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/photo_view_state.dart';
import 'photo_view_access_host.dart';

/// Overlay for the one-time photo states. Put it as the last child of a Stack.
class PhotoViewOverlay extends StatelessWidget {
  const PhotoViewOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final access = PhotoViewScope.maybeOf(context);
    if (access == null || !access.controlsAccess) {
      return const SizedBox.shrink();
    }
    final state = access.state;
    return switch (state.phase) {
      PhotoViewPhase.viewing when !state.isConcealed => _Countdown(
        seconds: state.secondsRemaining,
      ),
      PhotoViewPhase.available => _CenteredPanel(
        icon: Icons.visibility_outlined,
        child: QeranButton(
          label: LocaleKeys.likes_matches_photo_view_show.t(context),
          onPressed: state.isStarting ? null : access.onReveal,
          loading: state.isStarting,
          variant: QeranButtonVariant.primaryWine,
          size: QeranButtonSize.sm,
        ),
      ),
      PhotoViewPhase.consumed => _CenteredPanel(
        icon: Icons.lock_clock_outlined,
        child: Text(
          LocaleKeys.likes_matches_photo_view_consumed.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.subtitle.copyWith(color: QeranColors.paper),
        ),
      ),
      PhotoViewPhase.failure => _CenteredPanel(
        icon: Icons.lock_outline_rounded,
        child: QeranButton(
          label: LocaleKeys.likes_matches_photo_view_retry.t(context),
          onPressed: access.onRetry,
          variant: QeranButtonVariant.ghost,
          size: QeranButtonSize.sm,
        ),
      ),
      PhotoViewPhase.initial ||
      PhotoViewPhase.loading ||
      PhotoViewPhase.viewing => const _CenteredPanel(
        icon: Icons.lock_outline_rounded,
        child: CircularProgressIndicator(color: QeranColors.gold),
      ),
      PhotoViewPhase.unavailable => const SizedBox.shrink(),
    };
  }
}

class _Countdown extends StatelessWidget {
  final int seconds;
  const _Countdown({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.likes_matches_photo_view_remaining
        .t(context)
        .replaceFirst('{seconds}', '$seconds');
    return PositionedDirectional(
      top: QeranSpacing.s16,
      start: 0,
      end: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s12,
              vertical: QeranSpacing.s8,
            ),
            decoration: const BoxDecoration(
              color: QeranColors.overlayTintDark,
              borderRadius: QeranRadii.pill,
            ),
            child: Text(
              label,
              style: QeranTypography.label.copyWith(color: QeranColors.gold),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredPanel extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _CenteredPanel({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: QeranColors.overlayTintDark,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(QeranSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: QeranColors.gold),
                QeranSpacing.vs16,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
