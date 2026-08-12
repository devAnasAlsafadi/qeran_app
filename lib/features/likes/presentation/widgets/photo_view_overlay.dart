import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
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
      // The window is open and nothing is drawn over the photos. The countdown
      // badge used to live here; it is gone by design — the member watches the
      // photos, not a clock, and the end of the window announces itself.
      PhotoViewPhase.viewing when !state.isConcealed => const SizedBox.shrink(),
      PhotoViewPhase.available => _CenteredPanel(
        // No icon above the panel: the eye now rides inside the button label,
        // so the reveal action reads as one thing rather than two.
        child: QeranButton(
          label: LocaleKeys.likes_matches_photo_view_show.t(context),
          onPressed: state.isStarting ? null : access.onReveal,
          loading: state.isStarting,
          variant: QeranButtonVariant.primaryWine,
          size: QeranButtonSize.sm,
          leadingIcon: Icons.visibility_outlined,
        ),
      ),
      PhotoViewPhase.consumed => _CenteredPanel(
        icon: Icons.lock_clock_outlined,
        child: Text(
          LocaleKeys.likes_matches_photo_view_expired.t(context),
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
        child: QeranLoader(),
      ),
      PhotoViewPhase.unavailable => const SizedBox.shrink(),
    };
  }
}

class _CenteredPanel extends StatelessWidget {
  /// Optional — the reveal panel carries its glyph inside the button instead.
  final IconData? icon;
  final Widget child;

  const _CenteredPanel({this.icon, required this.child});

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
                if (icon != null) ...[
                  Icon(icon, size: 40, color: QeranColors.gold),
                  QeranSpacing.vs16,
                ],
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
