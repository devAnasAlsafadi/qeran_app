import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_card_text.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_counter.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_image_tile.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_text_area.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_toolbar.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../composer_rig.dart';

/// Her writing area as the board draws it: no border and no box, the whole
/// space between her line and the counter over the toolbar, and her text
/// set as members will read it.
void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ComposerHarness());
  tearDown(() => h.guidelines.dispose());

  final field = find.byType(TextField);

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('[${locale.languageCode}] no border, box or padding of its '
        'own, under the app\'s theme too', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await pumpShippedStrings(
        tester,
        locale,
        child: Theme(
          data: QeranTheme.light(locale),
          child: ComposerTextArea(
            controller: controller,
            focusNode: focus,
            locked: false,
          ),
        ),
      );

      final decoration = tester
          .widget<InputDecorator>(find.byType(InputDecorator))
          .decoration;
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.filled, isFalse);
      expect(decoration.contentPadding, EdgeInsets.zero);
    });
  }

  testWidgets('her text and the hint are set as a published post\'s text, '
      'at the reading line height (1.75)', (tester) async {
    await startComposer(tester, h);

    final widget = tester.widget<TextField>(field);
    for (final style in [widget.style!, widget.decoration!.hintStyle!]) {
      expect(style.fontSize, PostCardText.style.fontSize);
      expect(style.fontWeight, PostCardText.style.fontWeight);
      expect(style.height, 1.75);
    }
    expect(widget.style!.color, PostCardText.style.color);
  });

  testWidgets('C1: the counter sits over the toolbar; the space between her '
      'line and it is where she writes', (tester) async {
    await startComposer(tester, h);

    final counter = tester.getRect(find.text('0 / 2000'));
    final toolbar = tester.getRect(find.byType(ComposerToolbar));
    expect(toolbar.top - counter.bottom, moreOrLessEquals(QeranSpacing.s12));
    expect(counter.top - tester.getRect(field).bottom, greaterThan(400));
  });

  testWidgets('a tap on the space under her draft brings the keyboard back, '
      'the cursor at the end of her text', (tester) async {
    await startComposer(tester, h);
    await tester.enterText(field, 'إرشاد');
    await tester.pump();
    final widget = tester.widget<TextField>(field);
    widget.controller!.selection = const TextSelection.collapsed(offset: 0);
    widget.focusNode!.unfocus();
    await tester.pump();
    expect(widget.focusNode!.hasFocus, isFalse);

    final counter = tester.getRect(find.text('5 / 2000'));
    final below = (tester.getRect(field).bottom + counter.top) / 2;
    await tester.tapAt(Offset(counter.center.dx, below));
    await tester.pump();

    expect(widget.focusNode!.hasFocus, isTrue);
    expect(
      widget.controller!.selection,
      const TextSelection.collapsed(offset: 5),
    );
  });

  testWidgets('C5: her images sit right under her text, not down by the '
      'counter', (tester) async {
    h.configure(
      const CommunityConfig(postTextMaxLength: 2000, maxImagesPerPost: 10),
    );
    h.picker.gallery = ['a.jpg'];
    await startComposer(tester, h);

    await tester.tap(find.text('Images').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    final tile = tester.getRect(find.byType(ComposerImageTile));
    expect(tile.top - tester.getRect(field).bottom, lessThan(80));
    final counter = tester.getRect(find.text('0 / 2000'));
    expect(counter.top - tile.bottom, greaterThan(200));
  });

  testWidgets('S19: limits that can\'t be read leave no counter and no empty '
      'strip over the toolbar', (tester) async {
    h.limitText(null);
    await startComposer(tester, h);

    expect(find.textContaining(' / '), findsNothing);
    final counter = tester.getRect(find.byType(ComposerCounter));
    expect(counter.height, 0);
  });
}
