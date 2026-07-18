/// How the matchmaker's commission [rate] is expressed. Backend-driven —
/// today the contract only sends `"percent"`; `"fixed"` is reserved for a
/// future per-purchase flat amount. The data layer maps the wire string
/// case-insensitively; an absent or unrecognised value resolves to `null`
/// (never fabricated), so the UI renders the rate forward-safely (no
/// unconditional `%`).
enum AffiliateCommissionType { percent, fixed }
