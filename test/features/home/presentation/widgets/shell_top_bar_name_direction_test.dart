import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shell_top_bar_host.dart';

MatchmakerInfo _named(String name) => MatchmakerInfo(
  matchmakerId: 'm1',
  name: name,
  profileImageUrl: null,
  conversationId: 9,
);

/// Her name is laid out in its own direction, not the UI's. The host's UI is
/// English, so an Arabic name is the case that shows it.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    // A phone's width, so a long name has to give way.
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  Future<void> pumpNamed(WidgetTester tester, String name) async =>
      pumpShellTopBar(
        tester,
        matchmaker: await matchmakerCubit(
          MyMatchmakerAssigned(info: _named(name)),
        ),
      );

  testWidgets('a long Arabic name gives way at its own end', (tester) async {
    const name = 'هدى عبدالرحمن محمد الخطيب الأنصاري الحسيني';
    await pumpNamed(tester, name);

    final line = tester.renderObject<RenderParagraph>(find.text(name));
    final first = line
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .single;

    expect(line.didExceedMaxLines, isTrue);
    // Its first letter sits at the edge an Arabic reader starts from; laid
    // out in the UI's direction, the ellipsis took that edge instead.
    expect(first.right, line.size.width);
  });

  testWidgets('a short Arabic name still starts where the UI starts', (
    tester,
  ) async {
    const name = 'هدى';
    await pumpNamed(tester, name);

    expect(
      tester.getTopLeft(find.text(name)).dx,
      tester.getTopLeft(find.text(LocaleKeys.shell_matchmaker_role)).dx,
    );
  });
}
