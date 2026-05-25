import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/realtime_status.dart';

/// Subtle inline banner that surfaces realtime drops.
///
/// Visible only when:
///   1. We have previously been connected (`hasEverBeenConnected`),
///      so the brief initial-connect window never shows a banner.
///   2. The current status is `reconnecting` or `disconnected`.
///
/// Calm burgundy pill — matches the rest of the Qeran chrome.
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
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: 6,
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
                color: AppColors.primary,
              ),
            )
          else
            const Icon(
              Icons.cloud_off_outlined,
              size: 14,
              color: AppColors.primary,
            ),
          const SizedBox(width: AppDimens.p8),
          Flexible(
            child: Text(
              labelKey.t(context),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
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
