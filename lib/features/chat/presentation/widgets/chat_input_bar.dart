import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Composer. 2000-char hard cap (server-enforced + local). Send button
/// is disabled while the trimmed content is empty OR a server-issued
/// cooldown is active.
class ChatInputBar extends StatefulWidget {
  static const int maxLength = 2000;

  /// Sends the text. Completes with false when it did not go out and belongs
  /// back in the field (a rate limit); true otherwise.
  final Future<bool> Function(String content) onSend;
  final bool sendDisabledByCooldown;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.sendDisabledByCooldown,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next == _hasText) return;
    setState(() => _hasText = next);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canSend => _hasText && !widget.sendDisabledByCooldown;

  Future<void> _handleSend() async {
    if (!_canSend) return;
    final raw = _controller.text;
    _controller.clear();
    final sent = await widget.onSend(raw);
    // A rate-limited message never went out. Give it back, unless the member
    // has already started typing something else.
    if (sent || !mounted || _controller.text.trim().isNotEmpty) return;
    _controller.value = TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.creamCanvas,
        border: Border(
          top: BorderSide(color: QeranColors.wine08),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s12,
        QeranSpacing.s8,
        QeranSpacing.s12,
        QeranSpacing.s8,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: QeranComposerField(
                controller: _controller,
                focusNode: _focus,
                maxLength: ChatInputBar.maxLength,
                hint: LocaleKeys.chat_composer_placeholder.t(context),
              ),
            ),
            QeranSpacing.hs8,
            QeranSendButton(enabled: _canSend, onPressed: _handleSend),
          ],
        ),
      ),
    );
  }
}
