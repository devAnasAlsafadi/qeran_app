import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Composer. 2000-char hard cap (server-enforced + local). Send button
/// is disabled while the trimmed content is empty OR a server-issued
/// cooldown is active.
class ChatInputBar extends StatefulWidget {
  static const int maxLength = 2000;

  final Future<void> Function(String content) onSend;
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

  void _handleSend() {
    if (!_canSend) return;
    final raw = _controller.text;
    _controller.clear();
    widget.onSend(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s16,
                  vertical: QeranSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: QeranColors.creamSurface,
                  borderRadius: QeranRadii.pill,
                  border: Border.all(color: QeranColors.wine08),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: ChatInputBar.maxLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(ChatInputBar.maxLength),
                  ],
                  textInputAction: TextInputAction.newline,
                  style: QeranTypography.body
                      .copyWith(color: QeranColors.inkStrong),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    hintText:
                        LocaleKeys.chat_composer_placeholder.t(context),
                    hintStyle: QeranTypography.body
                        .copyWith(color: QeranColors.inkMuted),
                    counterText: '',
                  ),
                ),
              ),
            ),
            QeranSpacing.hs8,
            _SendButton(enabled: _canSend, onPressed: _handleSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _SendButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? QeranColors.gold
          : QeranColors.gold.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              Icons.send_rounded,
              size: 20,
              color: QeranColors.wine,
            ),
          ),
        ),
      ),
    );
  }
}
