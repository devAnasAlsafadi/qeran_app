import 'package:flutter/widgets.dart';

/// The first strongly directional character: a letter, or an explicit mark.
final _strong = RegExp(r'[\p{L}‎‏؜]', unicode: true);

/// Right-to-left scripts — Hebrew, Arabic, Syriac, Thaana, N'Ko and their
/// presentation forms — and the right-to-left marks.
final _rtl = RegExp(
  r'[֐-ࣿיִ-﷿ﹰ-﻿‏؜'
  r'\u{10800}-\u{10FFF}\u{1E800}-\u{1EFFF}]',
  unicode: true,
);

/// The direction [text] reads in on its own — that of its first letter, as
/// Unicode's paragraph rule has it — or null when it has none (digits, emoji,
/// punctuation), which leaves the UI's.
///
/// For text people wrote, which is in whichever language they wrote it —
/// names, and the text of posts, comments and replies. Laid out this way, an
/// Arabic name in the English UI truncates at its own end, never its start.
TextDirection? ownTextDirection(String text) {
  final first = _strong.firstMatch(text)?.group(0);
  if (first == null) return null;
  return _rtl.hasMatch(first) ? TextDirection.rtl : TextDirection.ltr;
}
