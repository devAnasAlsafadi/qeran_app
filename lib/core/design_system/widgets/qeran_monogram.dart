import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_own_text.dart';

/// [QeranMonogram]'s two looks.
enum QeranMonogramTone {
  /// A wine disc, a gold ring and a gold initial — the brand look.
  brand,

  /// A cream disc and a wine initial, no ring — a member in Community, who
  /// never shows a photo (D10).
  plain,
}

/// The monogram avatar, used wherever a person has no photo (dashboard
/// greeting, the matchmaker user cards' avatar fallback, Community rows).
/// When [name] is null/empty it shows a neutral person glyph instead of an
/// initial.
///
/// The initial is drawn in its own script's font (D13), so an Arabic initial
/// keeps real Noto Kufi Arabic glyphs in the English UI, and a Latin one
/// Montserrat in the Arabic UI.
class QeranMonogram extends StatelessWidget {
  const QeranMonogram({
    super.key,
    required this.name,
    this.size = 48,
    this.borderWidth = 2,
    this.borderRadius,
    this.tone = QeranMonogramTone.brand,
  });

  /// The person's name; the first grapheme becomes the initial. Null/empty
  /// falls back to the neutral person glyph.
  final String? name;

  final double size;
  final double borderWidth;

  /// When set, the monogram renders as a rounded-square with this radius
  /// (matching a rounded-square avatar). Null → the default circle.
  final BorderRadius? borderRadius;

  final QeranMonogramTone tone;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';
    final initial = trimmed.isEmpty ? null : _initialOf(trimmed);
    final plain = tone == QeranMonogramTone.plain;
    final foreground = plain ? QeranColors.wine : QeranColors.gold;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: plain ? QeranColors.creamSurface : QeranColors.wine,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
        border: plain
            ? null
            : Border.all(color: QeranColors.gold, width: borderWidth),
      ),
      child: initial == null
          ? Icon(Icons.person_outline, size: size * 0.5, color: foreground)
          : Text(
              initial,
              style: QeranTypography.title.copyWith(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: foreground,
                fontFamily: QeranOwnText.fontFamilyFor(initial),
              ),
            ),
    );
  }

  static String _initialOf(String value) =>
      String.fromCharCodes(value.characters.first.runes).toUpperCase();
}
