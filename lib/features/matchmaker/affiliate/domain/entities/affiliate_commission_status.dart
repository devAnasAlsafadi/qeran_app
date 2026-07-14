/// Settlement state of one affiliate commission row. Exactly the three states
/// the backend contract defines; the wire string is matched case-insensitively
/// in the data layer, where an unrecognised value falls back to [pending] (the
/// neutral, not-yet-settled state) rather than dropping the row or crashing.
enum AffiliateCommissionStatus { pending, confirmed, reversed }
