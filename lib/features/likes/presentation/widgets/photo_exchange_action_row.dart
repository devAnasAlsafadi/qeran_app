import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Photo-exchange accept / reject circular buttons.
///
/// Visually identical to the Received-Likes action row (heart =
/// accept, X = reject) — same colors, sizes, shadows. The row uses
/// `MainAxisAlignment.end` so the group sits at the visual END of the
/// card: in Arabic RTL that resolves to the LEFT side of the card,
/// matching the existing Received-Likes placement.
class PhotoExchangeActionRow extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;
  final bool isRejecting;

  const PhotoExchangeActionRow({
    super.key,
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
  });

  @override
  Widget build(BuildContext context) {
    // While EITHER action is in flight on this row, both buttons are
    // disabled — a second tap on the other would race the first and
    // the cubit-side guard would silently drop it.
    final inFlight = isAccepting || isRejecting;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _CircularActionButton(
          onTap: inFlight ? null : onAccept,
          icon: Icons.favorite_rounded,
          backgroundColor: const Color(0xFFB12B41),
          iconColor: AppColors.white,
          hasShadow: true,
          showSpinner: isAccepting,
          tooltipKey: LocaleKeys.likes_matches_photo_exchange_action_accept,
        ),
        const SizedBox(width: AppDimens.p12),
        _CircularActionButton(
          onTap: inFlight ? null : onReject,
          icon: Icons.close_rounded,
          backgroundColor: const Color(0xFFF6F5F5),
          iconColor: AppColors.textMuted,
          hasShadow: false,
          showSpinner: isRejecting,
          tooltipKey: LocaleKeys.likes_matches_photo_exchange_action_reject,
        ),
      ],
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final bool hasShadow;
  final bool showSpinner;
  final String tooltipKey;

  const _CircularActionButton({
    required this.onTap,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.hasShadow = false,
    this.showSpinner = false,
    required this.tooltipKey,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltipKey.t(context),
      button: true,
      child: Tooltip(
        message: tooltipKey.t(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: showSpinner
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
