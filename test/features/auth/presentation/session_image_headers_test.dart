import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/auth/presentation/session_image_headers.dart';

import 'fake_session.dart';

/// What [sessionImageHeaders] gives [url] from inside [tree].
Future<Map<String, String>?> _headers(
  WidgetTester tester,
  String url, {
  required Widget Function(Widget) tree,
}) async {
  Map<String, String>? headers;
  await tester.pumpWidget(
    tree(
      Builder(
        builder: (context) {
          headers = sessionImageHeaders(context, url);
          return const SizedBox();
        },
      ),
    ),
  );
  return headers;
}

void main() {
  testWidgets('signed in: our server gets the token', (tester) async {
    expect(
      await _headers(tester, ourImageUrl, tree: withSession),
      fakeSessionBearer,
    );
  });

  testWidgets('signed in: another host gets nothing', (tester) async {
    expect(await _headers(tester, foreignImageUrl, tree: withSession), isNull);
  });

  testWidgets('signed out: nothing, even for our server', (tester) async {
    final headers = await _headers(
      tester,
      ourImageUrl,
      tree: (child) =>
          withSession(child, state: const UserSessionUnauthenticated()),
    );
    expect(headers, isNull);
  });

  testWidgets('no session in scope: nothing, and no crash', (tester) async {
    expect(await _headers(tester, ourImageUrl, tree: (child) => child), isNull);
  });
}
