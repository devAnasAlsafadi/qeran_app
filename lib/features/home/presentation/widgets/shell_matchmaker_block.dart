import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_dashed_ring.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_state.dart';
import 'package:qeran/features/chat/presentation/widgets/matchmaker_avatar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The member's matchmaker in the top bar: avatar, the role line «خطّابتك»,
/// her name, and «رسالة جديدة» while the chat has unread messages. The whole
/// block is one tap target that opens the chat.
///
/// Before she is known — the first read in flight or failed — only the role
/// line shows, over a neutral avatar; the tap still opens the chat, whose own
/// screens tell loading from failure. With no matchmaker assigned yet the name
/// slot says so, and the chip never shows.
class ShellMatchmakerBlock extends StatelessWidget {
  const ShellMatchmakerBlock({
    super.key,
    required this.matchmaker,
    required this.chatUnread,
    required this.onTap,
  });

  final MyMatchmakerState matchmaker;
  final int chatUnread;
  final VoidCallback onTap;

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final state = matchmaker;
    final info = state is MyMatchmakerKnown ? state.info : null;
    final assigning = state is MyMatchmakerNone;
    final unread = info != null && chatUnread > 0;
    final name =
        info?.name ??
        (assigning ? LocaleKeys.shell_matchmaker_assigning.t(context) : null);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: _label(context, name, unread),
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.controlR,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s4),
            child: Row(
              children: [
                switch (state) {
                  MyMatchmakerKnown(:final info) => MatchmakerAvatar(
                    url: info.profileImageUrl,
                    name: info.name,
                    size: _avatarSize,
                  ),
                  MyMatchmakerNone() => const _AssigningDisc(),
                  MyMatchmakerUnknown() => const QeranMonogram(
                    name: null,
                    size: _avatarSize,
                    borderWidth: 1.2,
                  ),
                },
                QeranSpacing.hs12,
                Flexible(
                  child: _Lines(name: name, muted: assigning),
                ),
                if (unread) ...[
                  QeranSpacing.hs8,
                  QeranChip(
                    label: LocaleKeys.shell_chat_unread.t(context),
                    variant: QeranChipVariant.highlight,
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context, String? name, bool unread) {
    if (name == null) return LocaleKeys.shell_matchmaker_role.t(context);
    return (unread
            ? LocaleKeys.shell_chat_entry_a11y_unread
            : LocaleKeys.shell_chat_entry_a11y)
        .t(context, namedArgs: {'name': name});
  }
}

/// Role over name; the name is the one that gives way when space runs out.
class _Lines extends StatelessWidget {
  const _Lines({required this.name, required this.muted});

  final String? name;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.shell_matchmaker_role.t(context),
          style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (name != null)
          Text(
            name!,
            style: QeranTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: muted ? QeranColors.inkMuted : QeranColors.inkStrong,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// No matchmaker yet: a dashed gold ring around an hourglass — waiting, not
/// missing.
class _AssigningDisc extends StatelessWidget {
  const _AssigningDisc();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: ShellMatchmakerBlock._avatarSize,
      child: QeranDashedRing(
        color: QeranColors.goldDeep,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QeranColors.creamSurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 20,
              color: QeranColors.goldDeep,
            ),
          ),
        ),
      ),
    );
  }
}
