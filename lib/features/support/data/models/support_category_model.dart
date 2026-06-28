import '../../domain/entities/support_category.dart';
import '../json_parsers.dart';

/// Wire model for one `/api/support/categories` row:
/// `{ id, nameAr, nameEn, icon }` (icon = emoji | URL | null).
class SupportCategoryModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? icon;

  const SupportCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon,
  });

  factory SupportCategoryModel.fromJson(Map<String, dynamic> json) =>
      SupportCategoryModel(
        id: parseInt(json['id']),
        nameAr: parseString(json['nameAr']),
        nameEn: parseString(json['nameEn']),
        icon: parseNullableString(json['icon']),
      );

  SupportCategory toEntity() => SupportCategory(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
      );
}
