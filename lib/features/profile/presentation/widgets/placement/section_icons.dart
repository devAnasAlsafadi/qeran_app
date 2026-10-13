import 'package:flutter/material.dart';

import '../../../domain/entities/placement.dart';

/// The icon beside a profile section's title, chosen by the category's
/// dashboard key (TQ18): a key we know has its icon; `other`, an unset key
/// (null) and a key we don't know get the default.
///
/// Until Tariq's deploy the payload carries no `categoryKey`, and the icon
/// goes by the section's name: the key that name stands for, so the icon is
/// the same either side of the deploy.
IconData sectionIconFor(Placement placement) {
  if (placement.hasCategoryKey) {
    final key = placement.categoryKey?.trim().toLowerCase();
    return _byKey[key] ?? _defaultIcon;
  }
  return _byKey[_keyByName(placement.name)] ?? _defaultIcon;
}

const IconData _defaultIcon = Icons.list_alt_rounded;

/// The keys sent to Tariq (`14`, TQ18), one per live category. `other` and
/// «بدون تصنيف» (null) are left out on purpose: they take the default.
const Map<String, IconData> _byKey = {
  'personal': Icons.badge_outlined,
  'values': Icons.mosque_outlined,
  'marriage': Icons.diversity_1_outlined,
  'work': Icons.work_outline_rounded,
  'about': Icons.person_search_outlined,
  'personality': Icons.psychology_outlined,
};

/// TO REMOVE after Tariq's deploy (`14`, TQ18), with
/// [Placement.hasCategoryKey]: the key a live category's name stands for, so
/// its icon is the same before and after the deploy. Matched on a word of the
/// dashboard's name (AR and EN), ignoring Arabic marks and the tatweel; a name
/// it doesn't know takes the default.
String? _keyByName(String name) {
  final bare = name.replaceAll(_marks, '').toLowerCase();
  for (final (words, key) in _keyWords) {
    if (words.any(bare.contains)) return key;
  }
  return null;
}

final RegExp _marks = RegExp('[\u0640\u064B-\u065F\u0670]');

/// Each list names words only its own category's name has («الشخصية» is in
/// two, so it is in neither).
const List<(List<String>, String)> _keyWords = [
  (['السمات', 'personality'], 'personality'),
  (['المعلومات', 'personal information'], 'personal'),
  (['القيم', 'values'], 'values'),
  (['الزوجية', 'marital'], 'marriage'),
  (['الوظيفة', 'الدخل', 'work'], 'work'),
  (['شريك', 'partner'], 'about'),
];
