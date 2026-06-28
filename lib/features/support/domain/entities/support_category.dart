import 'package:equatable/equatable.dart';

/// A support problem-type the user picks before sending a request. The backend
/// owns this list (add/hide/remove server-side) — render exactly what it sends.
/// [icon] is an optional emoji (or URL, or null); rendered as a leading glyph
/// only when it's a short non-URL string.
class SupportCategory extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? icon;

  const SupportCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon,
  });

  /// The category label in the active language (`ar` → Arabic, else English).
  String localizedName(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  /// An emoji/glyph safe to render inline — null when absent or a remote URL.
  String? get inlineIcon {
    final value = icon;
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return null;
    return value;
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, icon];
}
