import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_notice.dart';
import 'package:qeran/features/community/presentation/widgets/feed/community_gate_notice.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_gate_banner.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../fake_profile_gate.dart';

/// [child] for the member at [status], in the English UI.
Future<void> _pump(WidgetTester tester, ProfileStatus? status, Widget child) =>
    pumpShippedStrings(
      tester,
      const Locale('en'),
      child: BlocProvider<ProfileGateCubit>.value(
        value: FakeGate(status),
        child: Column(children: [child]),
      ),
    );

/// The notice [child] draws for [status]: its icon and its text.
Future<(IconData?, String?)> _notice(
  WidgetTester tester,
  ProfileStatus status,
  Widget child,
) async {
  await _pump(tester, status, child);
  final notice = tester.widget<QeranNotice>(find.byType(QeranNotice));
  return (notice.icon, notice.text);
}

const _copy = {
  ProfileStatus.pendingReview: (
    Icons.hourglass_top_rounded,
    'Your profile is awaiting review',
  ),
  ProfileStatus.hidden: (
    Icons.visibility_off_rounded,
    'Your profile is currently hidden',
  ),
  ProfileStatus.rejected: (
    Icons.error_outline_rounded,
    'Your profile was declined — please contact your matchmaker',
  ),
};

void main() {
  setUpAll(initShippedStrings);

  group('a gated member: the design-system notice, its status icon', () {
    for (final MapEntry(key: status, value: (icon, text)) in _copy.entries) {
      testWidgets(status.name, (tester) async {
        final banner = await _notice(tester, status, const ProfileGateBanner());
        expect(banner, (icon, text));
      });

      testWidgets('${status.name}: the same icon as on Community', (
        tester,
      ) async {
        final (likes, _) = await _notice(
          tester,
          status,
          const ProfileGateBanner(),
        );
        final (community, _) = await _notice(
          tester,
          status,
          const CommunityGateNotice(),
        );
        expect(likes, community);
      });
    }
  });

  for (final status in [ProfileStatus.visible, null]) {
    testWidgets('${status?.name ?? 'not known yet'}: no notice', (
      tester,
    ) async {
      await _pump(tester, status, const ProfileGateBanner());

      expect(find.byType(QeranNotice), findsNothing);
    });
  }
}
