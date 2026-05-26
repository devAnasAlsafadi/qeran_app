import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Routed when a Stage-2 match card with `conversationId != null` is
/// tapped. MVP placeholder — the real conversation UI is a separate
/// work-stream. The `conversationId` is shown only in debug builds so
/// QA can verify the navigation argument while not exposing it to
/// users.
class MatchmakerChatScreenArgs {
  final String conversationId;
  const MatchmakerChatScreenArgs({required this.conversationId});
}

class MatchmakerChatScreen extends StatelessWidget {
  final MatchmakerChatScreenArgs args;
  const MatchmakerChatScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          LocaleKeys.likes_matchmaker_chat_title.t(context),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimens.p16),
              Text(
                LocaleKeys.likes_matchmaker_chat_placeholder.t(context),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppDimens.p16),
                Text(
                  'conversationId: ${args.conversationId}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
