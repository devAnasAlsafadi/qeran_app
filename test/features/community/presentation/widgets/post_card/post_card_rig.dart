import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';

import '../../../../../core/shipped_strings_rig.dart';

/// [post] as a card [width] wide, in [locale] with the shipped strings, in a
/// scrolling column as the feed has it.
Future<void> pumpCard(
  WidgetTester tester,
  CommunityPost post, {
  Locale locale = const Locale('en'),
  CommunityPostCardMode mode = CommunityPostCardMode.feed,
  bool readOnly = false,
  VoidCallback? onLike,
  VoidCallback? onOpenDiscussion,
  double width = 358,
}) => pumpShippedStrings(
  tester,
  locale,
  child: SingleChildScrollView(
    child: Center(
      child: SizedBox(
        width: width,
        child: CommunityPostCard(
          post: post,
          mode: mode,
          readOnly: readOnly,
          onLike: onLike,
          onOpenDiscussion: onOpenDiscussion,
        ),
      ),
    ),
  ),
);

/// Both UI languages, and what each one writes.
final cardLocales = {
  Locale('ar'): (
    like: 'إعجاب',
    discuss: 'ابدأ النقاش',
    discussion: 'النقاش',
    matchmaker: 'خطّابة',
    twoHoursAgo: 'منذ ساعتين',
    likes1240: '1.2 ألف',
    comments1500: '1.5 ألف',
  ),
  Locale('en'): (
    like: 'Like',
    discuss: 'Discuss',
    discussion: 'Discussion',
    matchmaker: 'Matchmaker',
    twoHoursAgo: '2 hours ago',
    likes1240: '1.2K',
    comments1500: '1.5K',
  ),
};
