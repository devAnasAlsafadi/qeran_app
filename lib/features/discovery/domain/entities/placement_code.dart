/// The canonical position a [Placement] occupies in the UI.
///
/// Server-side codes map to enum values via [fromInt]. Codes the client
/// does not recognize cause the parent placement to be dropped (see
/// `PlacementModel.tryParse`).
enum PlacementCode {
  aboveImage,
  aboutMe,
  insideCard,
  aboutPartner,
  interests,

  /// Server's `placementCode: 0` — a generic Q&A group whose section
  /// header comes from `placementName`. Named `defaultGroup` because
  /// `default` is a reserved word.
  defaultGroup;

  static PlacementCode? fromInt(int code) {
    return switch (code) {
      0 => PlacementCode.defaultGroup,
      1 => PlacementCode.aboveImage,
      2 => PlacementCode.aboutMe,
      3 => PlacementCode.insideCard,
      4 => PlacementCode.aboutPartner,
      5 => PlacementCode.interests,
      _ => null,
    };
  }
}
