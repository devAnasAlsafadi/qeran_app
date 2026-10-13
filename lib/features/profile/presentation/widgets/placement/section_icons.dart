import 'package:flutter/material.dart';

import '../../../domain/entities/placement.dart';

/// The icon beside a profile section's title, chosen by the category's
/// dashboard key (TQ18): a key we know has its icon; `other`, an unset key
/// (null) and a key we don't know get the default.
///
/// Until Tariq's deploy the payload carries no `categoryKey`, and the icon
/// goes by the section's name, as it did since run 7.
IconData sectionIconFor(Placement placement) {
  if (placement.hasCategoryKey) {
    final key = placement.categoryKey?.trim().toLowerCase();
    return _byKey[key] ?? _defaultIcon;
  }
  return _byName(placement.name);
}

const IconData _defaultIcon = Icons.list_alt_rounded;

/// The keys proposed to Tariq (`17`, run 9). `other` is left out on purpose:
/// it takes the default.
const Map<String, IconData> _byKey = {
  'personal': Icons.badge_outlined,
  'religion': Icons.mosque_outlined,
  'marriage': Icons.diversity_1_outlined,
  'work': Icons.work_outline_rounded,
  'education': Icons.school_outlined,
};

/// TO REMOVE after Tariq's deploy (`14`, TQ18), with
/// [Placement.hasCategoryKey]: the icon by the section's name, matched on
/// words, not whole names, ignoring Arabic marks and the tatweel, so a respelt
/// «الحياة الزوجيّة» still finds its icon. A name it doesn't know keeps the
/// default.
IconData _byName(String name) {
  final bare = name.replaceAll(_marks, '').toLowerCase();
  for (final (words, icon) in _byWords) {
    if (words.any(bare.contains)) return icon;
  }
  return _defaultIcon;
}

final RegExp _marks = RegExp('[\u0640\u064B-\u065F\u0670]');

const List<(List<String>, IconData)> _byWords = [
  (['الدين', 'religion'], Icons.mosque_outlined),
  (['الزوجية', 'الزواج', 'marri'], Icons.diversity_1_outlined),
  (
    ['الوظيفة', 'العمل', 'الدخل', 'work', 'job', 'income'],
    Icons.work_outline_rounded,
  ),
  (['التعليم', 'education'], Icons.school_outlined),
  (['الشخصية', 'personal'], Icons.badge_outlined),
];
