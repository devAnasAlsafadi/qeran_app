import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_about_me.dart';

void main() {
  group('DiscoveryAboutMe', () {
    testWidgets('renders the header and body text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DiscoveryAboutMe(
            header: 'نبذة عني',
            text: 'شخصية طموحة',
          ),
        ),
      ));
      expect(find.text('نبذة عني'), findsOneWidget);
      expect(find.text('شخصية طموحة'), findsOneWidget);
    });

    testWidgets('truncates the body text to the configured maxLines',
        (tester) async {
      const longText =
          'line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8';

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: DiscoveryAboutMe(
              header: 'h',
              text: longText,
              maxLines: 2,
            ),
          ),
        ),
      ));

      // Find the Text widget that has the body content.
      final bodyText = tester.widget<Text>(find.text(longText));
      expect(bodyText.maxLines, 2);
      expect(bodyText.overflow, TextOverflow.ellipsis);
    });
  });
}
