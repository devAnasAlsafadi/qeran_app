import 'package:flutter/widgets.dart';

import '../../constants/app_constants.dart';
import '../../utils/own_text_direction.dart';

/// Text people wrote — names, and the text of posts, comments and replies —
/// in its own direction **and** its own script's font (D13), whatever the
/// UI's language: an Arabic post in the English UI reads right to left in
/// Noto Kufi Arabic, an English comment in the Arabic UI left to right in
/// Montserrat. The theme picks one family per locale, so without this an
/// Arabic name in the English UI would fall back to a system font.
///
/// Text with no letters (digits, emoji) keeps the UI's direction and font.
/// Laid out this way a name truncates at its own end, never its start (B2).
class QeranOwnText extends StatelessWidget {
  const QeranOwnText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  /// The font family of [text]'s own script, or null to keep the UI's.
  static String? fontFamilyFor(String text) => switch (ownTextDirection(text)) {
        TextDirection.rtl => AppConstants.fontFamilyArabic,
        TextDirection.ltr => AppConstants.fontFamilyEnglish,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final family = fontFamilyFor(text);
    return Text(
      text,
      textDirection: ownTextDirection(text),
      style: family == null
          ? style
          : (style ?? const TextStyle()).copyWith(fontFamily: family),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }
}
