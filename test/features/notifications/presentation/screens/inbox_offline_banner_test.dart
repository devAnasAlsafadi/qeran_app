// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_inbox_tile.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'inbox_host.dart';

/// Offline, the inbox shows the banner under its app bar, so the back chevron
/// and "mark all as read" stay reachable.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  testWidgets('the banner sits under the app bar, the rows under it', (
    tester,
  ) async {
    await pumpInbox(tester, offline: true);

    expect(find.text(LocaleKeys.errors_offline), findsOneWidget);
    final banner = tester.getRect(
      find
          .ancestor(
            of: find.text(LocaleKeys.errors_offline),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(banner.top, tester.getRect(find.byType(AppBar)).bottom);
    expect(
      tester.getRect(find.byType(NotificationInboxTile).first).top,
      greaterThanOrEqualTo(banner.bottom),
    );
  });

  testWidgets('online, nothing sits between the app bar and the rows', (
    tester,
  ) async {
    await pumpInbox(tester, offline: false);

    expect(find.text(LocaleKeys.errors_offline), findsNothing);
  });
}
