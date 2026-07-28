import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_user_profile.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_editable_answers_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/update_text_answer_usecase.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_answer_save_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/widgets/matchmaker_profile_edit_host.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/about_me_section.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/about_partner_section.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/text_answer_edit_scope.dart';

/// #7 — the matchmaker's edit pencil on the two نبذات.
///
/// These sections paint their body directly instead of going through
/// PlacementItemRenderer, so they never picked up the pencil that Q&A rows
/// had. These tests pin both halves: the pencil appears under the matchmaker
/// edit scope, and NOTHING changes for everyone else.

final _pencil = find.byIcon(Icons.edit_outlined);

Placement _narrative(
  PlacementCode code, {
  String body = 'نبذة',
  PlacementItemType type = PlacementItemType.text,
}) => Placement(
  code: code,
  name: code == PlacementCode.aboutMe ? 'نبذة عني' : 'نبذة عن شريك الحياة',
  items: body.isEmpty
      ? const []
      : [
          PlacementItem(
            questionId: code == PlacementCode.aboutMe ? 11 : 22,
            question: 'q',
            type: type,
            value: PlacementSingle(body),
            display: PlacementSingle(body),
          ),
        ],
);

/// The sections under an explicitly installed scope — the matchmaker host's
/// end state, without needing the host itself.
Widget _scoped(List<Widget> sections, {List<PlacementItem> edited = const []}) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: TextAnswerEditScope(
          onEdit: edited.add,
          child: Column(children: sections),
        ),
      ),
    ),
  );
}

/// The same sections with NO scope — the user app / my-profile surface.
Widget _unscoped(List<Widget> sections) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: Column(children: sections)),
  ),
);

class _StubAnswersRepository implements MatchmakerEditableAnswersRepository {
  @override
  Future<Either<Failure, String>> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  }) async => const Right('ok');
}

MatchmakerUserProfile _profile(ProfileStatus status) => MatchmakerUserProfile(
  userId: 'u1',
  name: 'أنس',
  email: 'a@b.c',
  gender: 'ذكر',
  birthDate: null,
  age: 30,
  profileStatus: status,
  hasAnsweredQuestions: true,
  profileImage: null,
  images: const [],
  placements: [
    _narrative(PlacementCode.aboutMe),
    _narrative(PlacementCode.aboutPartner),
  ],
);

/// The real host, so the STATUS gate is what is under test.
Widget _hosted(ProfileStatus status) {
  final profile = _profile(status);
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocProvider<MatchmakerAnswerSaveCubit>(
          create: (_) => MatchmakerAnswerSaveCubit(
            userId: 'u1',
            updateTextAnswer: UpdateTextAnswerUseCase(
              _StubAnswersRepository(),
            ),
          ),
          child: MatchmakerProfileEditHost(
            profile: profile,
            child: Column(
              children: [
                AboutMeSection(placement: profile.placements[0]),
                AboutPartnerSection(placement: profile.placements[1]),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('matchmaker edit scope active', () {
    testWidgets('About Me and About Partner each get a pencil', (tester) async {
      await tester.pumpWidget(
        _scoped([
          AboutMeSection(placement: _narrative(PlacementCode.aboutMe)),
          AboutPartnerSection(
            placement: _narrative(PlacementCode.aboutPartner),
          ),
        ]),
      );

      expect(_pencil, findsNWidgets(2));
    });

    testWidgets('tapping a pencil reports THAT section item', (tester) async {
      final edited = <PlacementItem>[];
      await tester.pumpWidget(
        _scoped([
          AboutMeSection(placement: _narrative(PlacementCode.aboutMe)),
          AboutPartnerSection(
            placement: _narrative(PlacementCode.aboutPartner),
          ),
        ], edited: edited),
      );

      await tester.tap(_pencil.last);
      await tester.pump();

      expect(edited.single.questionId, 22, reason: 'aboutPartner item');
    });

    testWidgets('no pencil when the backend sent no body', (tester) async {
      await tester.pumpWidget(
        _scoped([
          AboutMeSection(placement: _narrative(PlacementCode.aboutMe, body: '')),
          AboutPartnerSection(
            placement: _narrative(PlacementCode.aboutPartner, body: ''),
          ),
        ]),
      );

      expect(_pencil, findsNothing);
      expect(find.text('نبذة عني'), findsNothing);
    });

    testWidgets('no pencil on a non-text item', (tester) async {
      await tester.pumpWidget(
        _scoped([
          AboutMeSection(
            placement: _narrative(
              PlacementCode.aboutMe,
              type: PlacementItemType.select,
            ),
          ),
        ]),
      );

      expect(_pencil, findsNothing);
      // The body still renders — only the affordance is withheld.
      expect(find.text('نبذة'), findsOneWidget);
    });
  });

  group('no edit scope (regular user / my-profile)', () {
    testWidgets('neither section shows a pencil', (tester) async {
      await tester.pumpWidget(
        _unscoped([
          AboutMeSection(placement: _narrative(PlacementCode.aboutMe)),
          AboutPartnerSection(
            placement: _narrative(PlacementCode.aboutPartner),
          ),
        ]),
      );

      expect(_pencil, findsNothing);
    });

    testWidgets('layout is unchanged — no Row is introduced', (tester) async {
      await tester.pumpWidget(
        _unscoped([
          AboutMeSection(placement: _narrative(PlacementCode.aboutMe)),
        ]),
      );

      // The wrapper must be a pure pass-through: the only Row on screen is the
      // section header's own, so the paragraph is not re-flowed.
      expect(
        find.descendant(of: find.byType(AboutMeSection), matching: find.byType(Row)),
        findsOneWidget,
      );
      expect(find.text('نبذة'), findsOneWidget);
    });
  });

  group('status gate (MatchmakerProfileEditHost)', () {
    testWidgets('pendingReview installs the scope → pencils', (tester) async {
      await tester.pumpWidget(_hosted(ProfileStatus.pendingReview));
      expect(_pencil, findsNWidgets(2));
    });

    testWidgets('rejected installs the scope → pencils', (tester) async {
      await tester.pumpWidget(_hosted(ProfileStatus.rejected));
      expect(_pencil, findsNWidgets(2));
    });

    testWidgets('visible installs the scope → pencils', (tester) async {
      // The backend accepts post-approval text edits and leaves the profile
      // visible, so the common case — an already-approved user — is editable.
      await tester.pumpWidget(_hosted(ProfileStatus.visible));
      expect(_pencil, findsNWidgets(2));
    });

    testWidgets('hidden → NO pencils', (tester) async {
      // The one status still out: a withdrawn profile isn't in circulation,
      // so there is nothing to polish. Also proves the gate still gates.
      await tester.pumpWidget(_hosted(ProfileStatus.hidden));
      expect(_pencil, findsNothing);
    });
  });
}
