import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Accept and decline for an INCOMING photo-exchange request — the pair the
/// receiver sees on a stage-0 card.
///
/// Side by side when both labels fit, stacked when they do not, decided by
/// measuring rather than by a breakpoint. The labels say «قبول تبادل الصور» /
/// «رفض تبادل الصور» in full: naming the exchange is what keeps a decline
/// reading as declining a TRANSACTION rather than as judging someone's photos,
/// and that distinction is worth a row of height on a small screen.
///
/// Those two strings were briefly shortened to «قبول التبادل» / «رفض التبادل»
/// because the full pair clipped side by side at 320dp. This is the other
/// answer to the same measurement: keep the words, move the layout.
///
/// Extracted from `match_card_stage0.dart`, which was at 193 of its 200 lines
/// and could not hold a LayoutBuilder. Sibling to
/// `match_card_formal_step_responder_actions.dart` — the other responder pair,
/// which is ALWAYS stacked because «عدم الموافقة وإنهاء التوافق» fits beside
/// nothing.
class MatchCardPhotoExchangeActions extends StatelessWidget {
  const MatchCardPhotoExchangeActions({
    super.key,
    required this.canAccept,
    required this.canReject,
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
  });

  /// The server's verdict on each verb separately, read separately. The card
  /// never works out whose turn it is.
  final bool canAccept;
  final bool canReject;

  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;
  final bool isRejecting;

  /// The gap between the two buttons when they share a row.
  static const double _gap = QeranSpacing.s8;

  /// [QeranButton]'s own horizontal padding at [QeranButtonSize.xs], per side.
  ///
  /// Mirrored here rather than read from the button, which does not export it.
  /// If that padding ever changes this measurement drifts silently, so
  /// `match_card_photo_exchange_layout_test` pins the switch against the width
  /// at which the text ACTUALLY truncates rather than against this arithmetic.
  static const double _buttonHPad = QeranSpacing.s8;

  @override
  Widget build(BuildContext context) {
    final rejectLabel =
        LocaleKeys.likes_matches_photo_exchange_action_reject.t(context);
    final acceptLabel =
        LocaleKeys.likes_matches_photo_exchange_action_accept.t(context);

    final reject = QeranButton(
      label: rejectLabel,
      onPressed: canReject ? onReject : null,
      variant: QeranButtonVariant.secondary,
      size: QeranButtonSize.xs,
      loading: isRejecting,
    );
    final accept = QeranButton(
      label: acceptLabel,
      onPressed: canAccept ? onAccept : null,
      variant: QeranButtonVariant.primary,
      size: QeranButtonSize.xs,
      loading: isAccepting,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_fitsSideBySide(context, constraints.maxWidth, [
          rejectLabel,
          acceptLabel,
        ])) {
          // Same ORDER as the row it replaces, deliberately. Switching the
          // arrangement is the point; switching which button is where as well
          // would move the accept under the thumb that was reaching for
          // decline. Unlike the formal-step pair this decline ends nothing —
          // the matchmaker carries on — so there is no reason to demote it.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [reject, QeranSpacing.vs8, accept],
          );
        }
        return Row(
          children: [
            Expanded(child: reject),
            const SizedBox(width: _gap),
            Expanded(child: accept),
          ],
        );
      },
    );
  }

  /// Whether every label fits its half of [maxWidth] on one line.
  ///
  /// Measured against the style the buttons will actually render with —
  /// [DefaultTextStyle] merged with the token, which is what `Text` itself
  /// does — and through the viewer's [TextScaler]. Measuring against the bare
  /// token instead reports roughly DOUBLE for Arabic, because the token
  /// carries no family and falls back to a font that draws every glyph as a
  /// full em square. That mistake makes the pair stack on every screen.
  static bool _fitsSideBySide(
    BuildContext context,
    double maxWidth,
    List<String> labels,
  ) {
    final perLabel = (maxWidth - _gap) / 2 - _buttonHPad * 2;
    if (perLabel <= 0) return false;

    final style = DefaultTextStyle.of(context).style.merge(
      QeranTypography.label,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > perLabel) return false;
    }
    return true;
  }
}
