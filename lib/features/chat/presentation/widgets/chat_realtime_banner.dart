import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/realtime_status.dart';

/// Subtle inline banner that surfaces realtime drops.
///
/// Visible only when:
///   1. We have previously been connected (`hasEverBeenConnected`),
///      so the brief initial-connect window never shows a banner.
///   2. The current status is `reconnecting` or `disconnected`.
///
/// Calm wine pill — matches the rest of the Qeran chrome.
class ChatRealtimeBanner extends StatelessWidget {
  final RealtimeStatus status;
  final bool hasEverBeenConnected;

  const ChatRealtimeBanner({
    super.key,
    required this.status,
    required this.hasEverBeenConnected,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasEverBeenConnected) return const SizedBox.shrink();
    if (status == RealtimeStatus.connected ||
        status == RealtimeStatus.connecting) {
      return const SizedBox.shrink();
    }
    final isReconnecting = status == RealtimeStatus.reconnecting;
    final labelKey = isReconnecting
        ? LocaleKeys.chat_realtime_reconnecting
        : LocaleKeys.chat_realtime_disconnected;
    return Container(
      width: double.infinity,
      color: QeranColors.wine06,
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReconnecting)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: QeranColors.wine,
              ),
            )
          else
            const Icon(
              Icons.cloud_off_outlined,
              size: 14,
              color: QeranColors.wine,
            ),
          QeranSpacing.hs8,
          Flexible(
            child: Text(
              labelKey.t(context),
              style: QeranTypography.caption.copyWith(
                color: QeranColors.wine,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
