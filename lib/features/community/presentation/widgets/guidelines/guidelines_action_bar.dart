import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// The guidelines' choice, pinned on the safe area (F5, J3): «أوافق وأتابع»
/// — off until there's text to agree to, a loader while it's sent — and
/// «ليس الآن», which waits while an agreement is on its way.
class GuidelinesActionBar extends StatelessWidget {
  const GuidelinesActionBar({
    super.key,
    required this.accepting,
    required this.onAgree,
    required this.onNotNow,
  });

  final bool accepting;
  final VoidCallback? onAgree;
  final VoidCallback onNotNow;

  static const _padding = EdgeInsetsDirectional.fromSTEB(
    QeranSpacing.s20,
    QeranSpacing.s12,
    QeranSpacing.s20,
    QeranSpacing.s8,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        border: Border(top: BorderSide(color: QeranColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: _padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buttons(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buttons(BuildContext context) => [
    QeranButton(
      label: LocaleKeys.community_guidelines_agree.t(context),
      variant: QeranButtonVariant.primaryWine,
      loading: accepting,
      onPressed: onAgree,
    ),
    QeranSpacing.vs4,
    QeranButton(
      label: LocaleKeys.community_guidelines_not_now.t(context),
      variant: QeranButtonVariant.ghost,
      size: QeranButtonSize.md,
      onPressed: accepting ? null : onNotNow,
    ),
  ];
}
