/// The server's comment rules, copied closely enough to hand-check the app
/// against the mock (D8). Not his full word list — the live filter is.
library;

import '../../error_codes.dart';
import 'community_mock_store.dart';

/// A comment's or a reply's gates after the injected ones, in the server's
/// order (contract §4): guidelines (members only), validation, the rate
/// limit, the filter.
class CommunityMockCommentGate {
  final bool viewerIsMatchmaker;
  bool guidelinesAccepted;
  final CommunityMockRateLimiter _limiter;

  CommunityMockCommentGate(
    DateTime Function() now, {
    required this.viewerIsMatchmaker,
    this.guidelinesAccepted = false,
  }) : _limiter = CommunityMockRateLimiter(now);

  void check(String text, {required int maxLength}) {
    if (!viewerIsMatchmaker && !guidelinesAccepted) {
      throwCommunityMockError(CommunityErrorCodes.guidelinesNotAccepted);
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) {
      throwCommunityMockError(CommunityErrorCodes.validationError);
    }
    if (_limiter.tryAcquire() case final int wait) {
      throwCommunityMockError(
        CommunityErrorCodes.rateLimited,
        data: {'retryAfterSeconds': wait},
      );
    }
    if (!CommunityMockFilter.allows(trimmed)) {
      throwCommunityMockError(CommunityErrorCodes.contentNotAllowed);
    }
  }
}

/// A simplified copy of the content filter (`03-api-contract.md` §10): 9+
/// digits (Arabic-Indic or Latin, separators allowed), e-mails, links and
/// domains, `@handles`, and a short list of contact words.
abstract final class CommunityMockFilter {
  static final _phone = RegExp(r'[0-9٠-٩](?:[\s\-.+()]*[0-9٠-٩]){8,}');
  static final _email = RegExp(r'[^\s@]+@[^\s@]+\.[^\s@]+');
  static final _link = RegExp(
    r'(https?://|www\.|\.(com|net|org|me)\b|t\.me|wa\.me|دوت كوم)',
    caseSensitive: false,
  );
  static final _handle = RegExp(r'(^|\s)@\w{2,}');
  static const _contactWords = [
    'واتس',
    'whatsapp',
    'تلغرام',
    'telegram',
    'سناب',
    'snapchat',
    'انستا',
    'instagram',
    'راسلني',
    'كلمني',
    'dm me',
  ];

  static bool allows(String text) {
    final lower = text.toLowerCase();
    if (_phone.hasMatch(text) ||
        _email.hasMatch(text) ||
        _link.hasMatch(lower) ||
        _handle.hasMatch(text)) {
      return false;
    }
    return !_contactWords.any(lower.contains);
  }
}

/// The comment + reply limit: 5 a minute and 60 an hour per user.
class CommunityMockRateLimiter {
  static const int perMinute = 5;
  static const int perHour = 60;

  final DateTime Function() _now;
  final List<DateTime> _sent = [];

  CommunityMockRateLimiter(this._now);

  /// Records the attempt and returns null when it's allowed; otherwise the
  /// seconds to wait, as the server's `retryAfterSeconds`.
  int? tryAcquire() {
    final now = _now();
    _sent.removeWhere((t) => now.difference(t) >= const Duration(hours: 1));
    final inLastMinute = _sent
        .where((t) => now.difference(t) < const Duration(minutes: 1))
        .toList(growable: false);
    if (inLastMinute.length >= perMinute) {
      return _secondsUntil(inLastMinute.first, const Duration(minutes: 1), now);
    }
    if (_sent.length >= perHour) {
      return _secondsUntil(_sent.first, const Duration(hours: 1), now);
    }
    _sent.add(now);
    return null;
  }

  static int _secondsUntil(DateTime oldest, Duration window, DateTime now) {
    final wait = window - now.difference(oldest);
    return wait.inSeconds < 1 ? 1 : wait.inSeconds;
  }
}
