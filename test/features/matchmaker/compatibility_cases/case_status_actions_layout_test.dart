import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/usecases/update_formal_request_status_usecase.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/blocs/matchmaker_case_status_cubit.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/case_status_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The status actions are the narrowest text in the case detail: full-width
/// buttons inside an s20 page inset, each carrying a leading icon and md's s20
/// horizontal padding. `QeranButton` draws its label with `maxLines: 1` and an
/// ellipsis, so a label that outgrows its slot truncates silently rather than
/// wrapping — on the one control that ends a case.
///
/// Measured against the SHIPPED fonts and the locale's real theme. The default
/// test font draws every glyph as a full em square and overstates Arabic by
/// roughly double, which would fail copy that fits comfortably on a device.
///
/// The closures are stacked rather than placed side by side. That decision was
/// made from measurement: two danger buttons sharing a row leave 68dp of text
/// at 320dp and ellipsise every label we have. Only one closure exists today —
/// a row of one and a stack of one render identically — so this file cannot
/// yet distinguish the two layouts. It guards the widths that ARE live, and
/// gains the two-button case for free when the negative terminals split.

class _MockUpdateUseCase extends Mock
    implements UpdateFormalRequestStatusUseCase {}

class _DiskLoader extends AssetLoader {
  const _DiskLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final file = File('assets/translations/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

Future<void> _loadFonts() async {
  const families = {
    'NotoKufiArabic': 'assets/fonts/NotoKufiArabic-Bold.ttf',
    'Montserrat': 'assets/fonts/Montserrat-Bold.ttf',
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(File(entry.value).readAsBytes().then(
            (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
          ));
    await loader.load();
  }
}

CompatibilityCase _case(FormalRequestStatus formal) {
  const user = CaseUser(
    userId: 'u',
    name: 'A',
    profileImageUrl: null,
    age: null,
    gender: null,
    isAssignedToMe: true,
  );
  return CompatibilityCase(
    caseId: 1,
    myUser: user,
    otherUser: user,
    likeAcceptedAt: null,
    stage: CompatibilityCaseStage.photoExchangeAccepted,
    photoExchange: null,
    formalRequest: CaseFormalRequest(id: 9, status: formal),
    chat: const CaseChat(
      myUserConversationId: null,
      otherUserConversationId: null,
      otherMatchmakerId: null,
      otherMatchmakerConversationId: null,
      otherMatchmakerName: null,
      otherMatchmakerImageUrl: null,
    ),
    canUpdateFormalRequestStatus: true,
    hasMyNote: false,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FormalRequestStatus formal,
  required Locale locale,
  double width = 320,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'unused',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: QeranTheme.light(locale),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: BlocProvider<MatchmakerCaseStatusCubit>(
              create: (_) => MatchmakerCaseStatusCubit(
                formalRequestId: 9,
                update: _MockUpdateUseCase(),
              ),
              // The page inset the detail screen actually uses — the buttons
              // are measured in the space they really get, not a bare screen.
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: CaseStatusActions(caseItem: _case(formal)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every button label currently on screen, with whether it had to ellipsise.
Map<String, bool> _labelTruncation(WidgetTester tester) {
  final out = <String, bool>{};
  for (final element in find
      .descendant(of: find.byType(QeranButton), matching: find.byType(Text))
      .evaluate()) {
    final text = element.widget as Text;
    final data = text.data;
    if (data == null) continue;
    out[data] = (element.renderObject as RenderParagraph).didExceedMaxLines;
  }
  return out;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
    await EasyLocalization.ensureInitialized();
  });

  // Both actionable stages, both languages, at the narrowest width we support.
  for (final formal in [
    FormalRequestStatus.waitingForParentAppointment,
    FormalRequestStatus.parentsVisited,
  ]) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final lang = locale.languageCode;
      testWidgets(
        'no action label truncates at 320dp — ${formal.name} [$lang]',
        (tester) async {
          await _pump(tester, formal: formal, locale: locale);

          final labels = _labelTruncation(tester);
          expect(labels, isNotEmpty, reason: 'no action buttons rendered');
          final truncated = labels.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
          expect(
            truncated,
            isEmpty,
            reason: 'truncated at 320dp in $lang: $truncated',
          );
        },
      );
    }
  }

  testWidgets('closures are laid out full width, not shared across a row', (
    tester,
  ) async {
    await _pump(
      tester,
      formal: FormalRequestStatus.parentsVisited,
      locale: const Locale('ar'),
    );

    // 320dp screen less the s20 page inset on each side.
    const expected = 320.0 - 40;
    for (final element in find.byType(QeranButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(element.widget)).width,
        expected,
        reason: 'an action button is not full width',
      );
    }
  });
}
