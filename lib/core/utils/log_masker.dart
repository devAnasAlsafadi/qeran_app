/// Utilities for masking sensitive values before they reach the logs.
///
/// Pure functions — no state, no I/O. Use these wherever a log statement
/// would otherwise contain a phone number, an OTP, or any other value that
/// must not be persisted in `dev.log` output.
class LogMasker {
  LogMasker._();

  static final RegExp _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );

  /// An email address, also URL-encoded (`%40`) as in a query string.
  static final RegExp _emailPattern = RegExp(
    r'[\w.+-]+(?:@|%40)[\w-]+(?:\.[\w-]+)+',
  );

  /// A phone-length number: 8 or more digits in a row, with or without `+`.
  /// Ids, counts, pages, dates and OTP lengths are shorter.
  static final RegExp _longNumberPattern = RegExp(r'\+?\d{8,}');

  /// Masks a phone number for safe logging.
  ///
  /// Keeps the first 3 and last 4 digits and replaces the middle with `*`.
  /// A leading `+` is preserved as a visible prefix; the 3+4 rule applies
  /// to the digits after it. Inputs that are null, empty, or shorter than
  /// 7 digits return `***`.
  ///
  /// Examples:
  /// - `970591234567`  → `970*****4567`
  /// - `+970591234567` → `+970*****4567`
  /// - `123`           → `***`
  /// - `null`          → `***`
  static String phone(String? value) {
    if (value == null || value.isEmpty) return '***';

    final hasPlus = value.startsWith('+');
    final digits = hasPlus ? value.substring(1) : value;

    if (digits.length < 7) return '***';

    final prefix = digits.substring(0, 3);
    final suffix = digits.substring(digits.length - 4);
    final stars = '*' * (digits.length - 7);

    return '${hasPlus ? '+' : ''}$prefix$stars$suffix';
  }

  /// Returns a length-only summary so an OTP value never reaches the log.
  ///
  /// Examples:
  /// - `'123456'` → `'otp_len=6'`
  /// - `null`     → `'otp_len=0'`
  static String otp(String? value) => 'otp_len=${value?.length ?? 0}';

  /// Removes JWTs from arbitrary diagnostic text before it is logged.
  static String secrets(String value) =>
      value.replaceAll(_jwtPattern, '<redacted-jwt>');

  /// What `AppLogger` applies to every debug line: [secrets], then email
  /// addresses and phone-length numbers. A debug log is still copied off the
  /// device by whoever holds it, so it carries no token and no contact detail.
  static String redact(String value) => secrets(value)
      .replaceAll(_emailPattern, '<redacted-email>')
      .replaceAll(_longNumberPattern, '<redacted-number>');
}
