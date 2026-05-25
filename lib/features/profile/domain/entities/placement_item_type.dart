/// Item type hint from the backend (`type` field on each placement
/// item). Drives optional renderer specialisation (e.g. height suffix,
/// interests chip styling). The renderer falls back to the
/// `PlacementValue` sealed shape if the type is unknown.
enum PlacementItemType {
  text,
  height,
  weight,
  date,
  select,
  multiSelect,
  interests,
  location,
  unknown;

  static PlacementItemType fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'text':
        return PlacementItemType.text;
      case 'height':
        return PlacementItemType.height;
      case 'weight':
        return PlacementItemType.weight;
      case 'date':
        return PlacementItemType.date;
      case 'select':
      case 'singleselect':
        return PlacementItemType.select;
      case 'multiselect':
      case 'checkbox':
        return PlacementItemType.multiSelect;
      case 'interests':
        return PlacementItemType.interests;
      case 'location':
        return PlacementItemType.location;
      default:
        return PlacementItemType.unknown;
    }
  }
}
