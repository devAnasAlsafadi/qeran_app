import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_typography.dart';

/// The brand monogram avatar — a wine disc with a gold ring and a gold
/// initial. Used wherever a person has no photo (dashboard greeting, the
/// matchmaker user cards' avatar fallback). When [name] is null/empty it
/// shows a neutral person glyph instead of an initial.
///
/// The initial uses the locale-aware body font (NOT the Montserrat numeric
/// style) so an Arabic initial renders with real glyphs.
class QeranMonogram extends StatelessWidget {
  const QeranMonogram({
    super.key,
    required this.name,
    this.size = 48,
    this.borderWidth = 2,
  });

  /// The person's name; the first grapheme becomes the initial. Null/empty
  /// falls back to the neutral person glyph.
  final String? name;

  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';
    final initial = trimmed.isEmpty ? null : _initialOf(trimmed);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: QeranColors.wine,
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: borderWidth),
      ),
      child: initial == null
          ? Icon(Icons.person_outline,
              size: size * 0.5, color: QeranColors.gold)
          : Text(
              initial,
              style: QeranTypography.title.copyWith(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: QeranColors.gold,
              ),
            ),
    );
  }

  static String _initialOf(String value) =>
      String.fromCharCodes(value.characters.first.runes).toUpperCase();
}
