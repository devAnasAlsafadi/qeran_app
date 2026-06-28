/// Machine-readable error codes the support endpoints return on a failure
/// envelope (`status: 0`). Branch on these instead of matching the Arabic
/// `message`. Source: backend support contract (POST /api/support/tickets).
class SupportErrorCodes {
  const SupportErrorCodes._();

  /// The caller already has 5 open tickets — must wait for one to be handled.
  static const String limitReached = 'SUPPORT_TICKETS_LIMIT_REACHED';

  /// The chosen `categoryId` is unknown or inactive server-side.
  static const String categoryNotFound = 'SUPPORT_CATEGORY_NOT_FOUND';

  /// Subject/details empty or over the length cap (200 / 4000).
  static const String validation = 'VALIDATION_ERROR';
}
