import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/own_text_direction.dart';
import '../../../../../generated/locale_keys.g.dart';

/// A post's text in its own direction and script (D13, A21). When
/// [collapsible] (the feed), a text longer than [collapsedLines] lines is cut
/// there with «عرض المزيد», which opens it in place (A2, A3); once open,
/// «عرض أقل» at its end folds it back. On the post screen it is always whole.
class PostCardText extends StatefulWidget {
  const PostCardText(
    this.text, {
    super.key,
    this.collapsible = true,
    this.onFolded,
  });

  final String text;
  final bool collapsible;

  /// «عرض أقل» folded the text back: the card brings its top into view.
  final VoidCallback? onFolded;

  static const int collapsedLines = 4;

  static final TextStyle style = QeranTypography.body.copyWith(
    color: QeranColors.inkStrong,
    height: QeranTypography.readingLineHeight,
  );

  @override
  State<PostCardText> createState() => _PostCardTextState();
}

class _PostCardTextState extends State<PostCardText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 2 * QeranSpacing.s16;
        final long =
            widget.collapsible && _exceeds(context, widget.text, width);
        return AnimatedSize(
          duration: QeranMotion.standard,
          curve: QeranCurves.standard,
          alignment: AlignmentDirectional.topStart,
          child: _body(long: long),
        );
      },
    );
  }

  /// The text — a [long] one cut at [PostCardText.collapsedLines] lines
  /// with «عرض المزيد» under it, or whole with «عرض أقل».
  Widget _body({required bool long}) {
    final cut = long && !_expanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s16,
            0,
            QeranSpacing.s16,
            long ? 0 : QeranSpacing.s12,
          ),
          child: QeranOwnText(
            widget.text,
            style: PostCardText.style,
            maxLines: cut ? PostCardText.collapsedLines : null,
            overflow: cut ? TextOverflow.ellipsis : null,
          ),
        ),
        if (long) _toggle(cut),
      ],
    );
  }

  Widget _toggle(bool cut) => _SeeToggle(
    label: cut ? LocaleKeys.community_see_more : LocaleKeys.community_see_less,
    onTap: () {
      setState(() => _expanded = cut);
      if (!cut) widget.onFolded?.call();
    },
  );

  /// Whether [text], laid out as [QeranOwnText] lays it out, runs past
  /// [PostCardText.collapsedLines] lines at [width].
  static bool _exceeds(BuildContext context, String text, double width) {
    final family = QeranOwnText.fontFamilyFor(text);
    final style = DefaultTextStyle.of(context).style.merge(
      family == null
          ? PostCardText.style
          : PostCardText.style.copyWith(fontFamily: family),
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ownTextDirection(text) ?? Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: PostCardText.collapsedLines,
    )..layout(maxWidth: width < 0 ? 0 : width);
    final exceeds = painter.didExceedMaxLines;
    painter.dispose();
    return exceeds;
  }
}

/// «عرض المزيد» or «عرض أقل» — lined up under the text's start, on the UI's
/// side.
class _SeeToggle extends StatelessWidget {
  const _SeeToggle({required this.label, required this.onTap});

  /// The key of its label.
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The ghost button's own 8 pt padding brings its label to 16.
      padding: const EdgeInsetsDirectional.only(
        start: QeranSpacing.s8,
        bottom: QeranSpacing.s4,
      ),
      child: QeranButton(
        label: label.t(context),
        onPressed: onTap,
        variant: QeranButtonVariant.ghost,
        size: QeranButtonSize.compact,
        fullWidth: false,
      ),
    );
  }
}
