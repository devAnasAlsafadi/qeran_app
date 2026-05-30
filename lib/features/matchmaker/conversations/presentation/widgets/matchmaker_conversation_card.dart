import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_count_badge.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_conversation.dart';

/// One conversation row: unblurred avatar + name with the last-message time
/// on the title line, and the preview (or a "shared profile" label) with the
/// unread badge on the subtitle line. Tappable; opening the chat screen is 4b.
class MatchmakerConversationCard extends StatelessWidget {
  const MatchmakerConversationCard({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final MatchmakerConversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        children: [
          MatchmakerUserAvatar(url: conversation.profileImageUrl, size: 52),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TitleRow(name: conversation.fullName, time: _time(context)),
                QeranSpacing.vs4,
                _SubtitleRow(conversation: conversation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _time(BuildContext context) {
    final at = conversation.lastMessageAt;
    if (at == null) return null;
    final local = at.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) {
      return LocaleKeys.matchmaker_conversations_time_now.t(context);
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}'
          '${LocaleKeys.matchmaker_conversations_time_minute.t(context)}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}'
          '${LocaleKeys.matchmaker_conversations_time_hour.t(context)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}'
          '${LocaleKeys.matchmaker_conversations_time_day.t(context)}';
    }
    try {
      return DateFormat.MMMd(context.locale.toString()).format(local);
    } catch (_) {
      final m = local.month.toString().padLeft(2, '0');
      final d = local.day.toString().padLeft(2, '0');
      return '${local.year}/$m/$d';
    }
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.name, required this.time});

  final String name;
  final String? time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: QeranTypography.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (time != null) ...[
          QeranSpacing.hs8,
          Text(
            time!,
            style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
          ),
        ],
      ],
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({required this.conversation});

  final MatchmakerConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _preview(context)),
        if (conversation.unreadCount > 0) ...[
          QeranSpacing.hs8,
          MatchmakerCountBadge(count: conversation.unreadCount),
        ],
      ],
    );
  }

  Widget _preview(BuildContext context) {
    if (conversation.isSharedProfilePreview) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 14,
            color: QeranColors.wine,
          ),
          QeranSpacing.hs4,
          Flexible(
            child: Text(
              LocaleKeys.matchmaker_conversations_shared_profile.t(context),
              style: QeranTypography.caption.copyWith(color: QeranColors.wine),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    final preview = conversation.lastMessagePreview ?? '';
    return Text(
      preview,
      style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
