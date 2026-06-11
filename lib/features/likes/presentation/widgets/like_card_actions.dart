import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Accept / reject circular buttons for an incoming pending like — gold
/// accept (wine heart, soft lift) + cream reject (wine ✕). While either
/// request is in flight both buttons disable so a second tap can't race
/// the first; the active one shows an inline loader.
class LikeCardActions extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;
  final bool isRejecting;

  const LikeCardActions({
    super.key,
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
  });

  @override
  Widget build(BuildContext context) {
    final inFlight = isAccepting || isRejecting;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircularButton(
          onTap: inFlight ? null : onAccept,
          icon: Icons.favorite_rounded,
          background: QeranColors.gold,
          hasShadow: true,
          showSpinner: isAccepting,
          tooltipKey: LocaleKeys.likes_action_accept,
        ),
        QeranSpacing.hs12,
        _CircularButton(
          onTap: inFlight ? null : onReject,
          icon: Icons.close_rounded,
          background: QeranColors.creamSurface,
          hasShadow: false,
          showSpinner: isRejecting,
          tooltipKey: LocaleKeys.likes_action_reject,
        ),
      ],
    );
  }
}

class _CircularButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color background;
  final bool hasShadow;
  final bool showSpinner;
  final String tooltipKey;

  const _CircularButton({
    required this.onTap,
    required this.icon,
    required this.background,
    required this.hasShadow,
    required this.showSpinner,
    required this.tooltipKey,
  });

  /// Tap target stays ~40 for usability; the painted circle is smaller so
  /// the controls read as refined secondary actions, not dominant.
  static const double _tapSize = 40;
  static const double _circleSize = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltipKey.t(context),
      button: true,
      child: Tooltip(
        message: tooltipKey.t(context),
        child: SizedBox(
          width: _tapSize,
          height: _tapSize,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: Container(
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: background,
                    boxShadow: hasShadow ? QeranShadows.e1 : null,
                  ),
                  child: Center(
                    child: showSpinner
                        ? const QeranLoader.inline(color: QeranColors.wine)
                        : Icon(icon, color: QeranColors.wine, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
