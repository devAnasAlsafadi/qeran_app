import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/services/language_service.dart';

/// The service feeds `Accept-Language` to every request, and now also answers
/// "was that a real switch?" — the difference between a user changing language
/// (everything already fetched is stale) and cold start merely adopting the
/// saved locale (nothing has been fetched yet).

void main() {
  test('starts on Arabic, mirroring the start locale', () {
    expect(LanguageService().currentLanguage, 'ar');
  });

  test('adopting the saved locale on launch is not a switch', () {
    final service = LanguageService();

    // English user, cold start: the first sync must not make the app refetch
    // what it has not fetched yet.
    expect(service.setLanguage('en'), isFalse);
    expect(service.currentLanguage, 'en');
  });

  test('changing language afterwards IS a switch', () {
    final service = LanguageService()..setLanguage('ar');

    expect(service.setLanguage('en'), isTrue);
    expect(service.currentLanguage, 'en');
  });

  test('re-setting the same language is not a switch', () {
    final service = LanguageService()..setLanguage('en');

    expect(service.setLanguage('en'), isFalse);
  });

  test('switching back and forth keeps reporting switches', () {
    final service = LanguageService()..setLanguage('ar');

    expect(service.setLanguage('en'), isTrue);
    expect(service.setLanguage('ar'), isTrue);
    expect(service.currentLanguage, 'ar');
  });
}
