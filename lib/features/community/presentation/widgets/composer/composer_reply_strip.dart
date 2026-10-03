import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Above the field while answering a comment (D2): «الرد على» and the name
/// — in its own direction, cut at its own end (B2) — and the close that goes
/// back to writing a comment.
class ComposerReplyStrip extends StatelessWidget {
  const ComposerReplyStrip({
    super.key,
    required this.name,
    required this.onClose,
  });

  final String name;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: QeranColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: QeranSpacing.s16),
        child: Row(
          children: [
            const Icon(
              Icons.reply_rounded,
              size: 16,
              color: QeranColors.inkMuted,
            ),
            const SizedBox(width: QeranSpacing.s6),
            Expanded(child: _who(context)),
            _Close(onTap: onClose),
          ],
        ),
      ),
    );
  }

  /// «الرد على» and the name.
  Widget _who(BuildContext context) => Row(
    children: [
      Text(
        LocaleKeys.community_replying_to.t(context),
        style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
      ),
      QeranSpacing.hs4,
      Expanded(
        child: QeranOwnText(
          name,
          style: QeranTypography.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    ],
  );
}

class _Close extends StatelessWidget {
  const _Close({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).closeButtonTooltip,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 48,
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: QeranColors.inkMuted,
          ),
        ),
      ),
    );
  }
}
