/// Page sizes the app asks for. The contract's default is 20; replies come 10
/// at a time (S21) — a thread opens short and grows on «عرض ردود أخرى».
abstract final class CommunityPageSizes {
  static const int feed = 20;
  static const int comments = 20;
  static const int replies = 10;
}
