import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/own_text_direction.dart';

import '../../domain/entities/matchmaker_info.dart';
import 'matchmaker_avatar.dart';

/// The chat's header: paper, running under the status bar, with a back
/// chevron whenever there is somewhere to go back to.
///
/// Two shapes. Before the conversation is known — loading, being assigned,
/// failure — it carries a plain title. Once it is, it shows the peer: avatar,
/// name, and an optional line under the name. Both are the same height, so the
/// header doesn't jump when the conversation arrives.
class ChatHeader extends StatelessWidget {
  const ChatHeader.title({super.key, required String this.title, this.onBack})
    : peer = null,
      subtitle = null,
      onTap = null;

  const ChatHeader.peer({
    super.key,
    required MatchmakerInfo this.peer,
    this.subtitle,
    this.onBack,
    this.onTap,
  }) : title = null;

  final String? title;
  final MatchmakerInfo? peer;

  /// A line under the peer's name. The member's side names the role; the
  /// matchmaker's side has none.
  final String? subtitle;

  final VoidCallback? onBack;
  final VoidCallback? onTap;

  /// The avatar's size — every shape of the header is at least this tall.
  static const double _rowHeight = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        border: Border(bottom: BorderSide(color: QeranColors.wine08)),
        boxShadow: QeranShadows.e1,
      ),
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s16,
        QeranSpacing.s12,
        QeranSpacing.s16,
        QeranSpacing.s12,
      ),
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _rowHeight),
            child: Row(
              children: [
                if (onBack != null) ...[
                  _HeaderBackButton(onBack: onBack!),
                  QeranSpacing.hs4,
                ],
                ..._content(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content() {
    final peer = this.peer;
    if (peer == null) {
      return [Expanded(child: _line(title!, QeranTypography.title))];
    }
    return [
      MatchmakerAvatar(url: peer.profileImageUrl, name: peer.name),
      QeranSpacing.hs12,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // In its own direction, so a long name gives way at its own end.
            _line(
              peer.name,
              QeranTypography.title,
              direction: ownTextDirection(peer.name),
            ),
            if (subtitle != null) _line(subtitle!, QeranTypography.caption),
          ],
        ),
      ),
    ];
  }

  static Widget _line(
    String text,
    TextStyle style, {
    TextDirection? direction,
  }) => Text(
    text,
    style: style,
    textDirection: direction,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Leading back affordance. Transparent host since the header is already on
/// a paper surface.
class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onBack,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: QeranColors.wine,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
