/// Canonical position a placement occupies in profile rendering.
///
/// Mirrors the integer `placementCode` shipped by backend. Unknown
/// codes degrade to [defaultGroup] so new server-side categories
/// render as generic Q&A blocks rather than disappear.
enum PlacementCode {
  defaultGroup,
  aboveImage,
  aboutMe,
  insideCard,
  aboutPartner,
  interests;

  static PlacementCode fromInt(int code) {
    return switch (code) {
      0 => PlacementCode.defaultGroup,
      1 => PlacementCode.aboveImage,
      2 => PlacementCode.aboutMe,
      3 => PlacementCode.insideCard,
      4 => PlacementCode.aboutPartner,
      5 => PlacementCode.interests,
      _ => PlacementCode.defaultGroup,
    };
  }
}
