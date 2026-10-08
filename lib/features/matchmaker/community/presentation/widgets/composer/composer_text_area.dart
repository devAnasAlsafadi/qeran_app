import 'package:flutter/material.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_card_text.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/utils/own_text_direction.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// Where she writes (C1, C2): no border and no box — the text as members
/// will read it, in a published post's style and reading line height, and in
/// its own direction as she types (D13). The space under her draft writes
/// too, and the counter sits over the toolbar (`ComposerBody`).
class ComposerTextArea extends StatelessWidget {
  const ComposerTextArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.locked,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Publishing: the draft can't change (S3).
  final bool locked;

  /// Spelled out in full: a collapsed decoration would still take the app
  /// theme's outline and padding for the borders and padding it leaves null.
  static InputDecoration _decoration(BuildContext context) => InputDecoration(
    hintText: LocaleKeys.matchmaker_community_composer_hint.t(context),
    hintStyle: PostCardText.style.copyWith(color: QeranColors.inkFaint),
    isCollapsed: true,
    contentPadding: EdgeInsets.zero,
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
  );

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        0,
        QeranSpacing.s20,
        QeranSpacing.s12,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: locked,
        autofocus: true,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textDirection: ownTextDirection(text),
        style: PostCardText.style.copyWith(
          fontFamily: QeranOwnText.fontFamilyFor(text),
        ),
        cursorColor: QeranColors.goldDeep,
        decoration: _decoration(context),
      ),
    );
  }
}
