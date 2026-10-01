import 'community_mock_records.dart';
import 'community_mock_seed.dart';

/// The board's threads on the first post — Sara with three replies (one from
/// the matchmaker), the viewer's own comment with Sara's reply, Abdullah,
/// Fahad's English comment (D13), Umm Khalid — then fillers, for 23
/// top-level comments: two pages at 20.
List<MockComment> seedComments(
  DateTime now, {
  required int firstPostId,
  required CommunityMockViewer viewer,
}) {
  var nextId = 5000;
  MockComment row(
    Map<String, dynamic> author,
    String text,
    Duration ago, {
    MockComment? parent,
    int likes = 0,
    bool liked = false,
  }) =>
      MockComment(
        id: nextId++,
        postId: firstPostId,
        parentId: parent?.id,
        author: author,
        text: text,
        likeCount: likes,
        likedByMe: liked,
        createdAt: now.subtract(ago),
      );

  final me = viewer.toAuthorJson();
  final sara = row(_sara, 'جزاكِ الله خيراً، كنت أظن أن الاستخارة لا تتم إلا برؤيا.',
      const Duration(hours: 1), likes: 12);
  final mine = row(me, 'أوافقكِ، السؤال عن الخاطب أهم خطوة.',
      const Duration(hours: 2), likes: 3);
  return [
    sara,
    row(CommunityMockSeed.huda,
        'وإياكِ. الرؤيا ليست شرطاً، والمهم أن تمضي في الأسباب وتطمئن.',
        const Duration(minutes: 40), parent: sara, likes: 9, liked: true),
    row(_ummKhalid, 'هذا ما قالته لنا خطّابتنا أيضاً، والحمد لله تيسّر الأمر.',
        const Duration(minutes: 30), parent: sara, likes: 2),
    row(_abdullah, 'وأنا كذلك، شكراً على التوضيح.',
        const Duration(minutes: 20), parent: sara),
    mine,
    row(_sara, 'صحيح، ونحن تأخرنا في هذه الخطوة.', const Duration(minutes: 5),
        parent: mine),
    row(_abdullah, 'هل يجوز تكرار الاستخارة إذا لم يتضح الأمر؟',
        const Duration(hours: 3), likes: 4),
    row(_fahad, 'Very helpful, thank you for sharing.',
        const Duration(hours: 5)),
    for (var i = 0; i < 18; i++)
      row(_people[i % _people.length], _fillers[i % _fillers.length],
          Duration(hours: 6 + i)),
    row(_ummKhalid, 'نسأل الله التيسير للجميع.', const Duration(days: 1),
        likes: 1),
  ];
}

Map<String, dynamic> _member(String id, String name) => {
      'id': id,
      'displayName': name,
      'isMatchmaker': false,
      'profileImageUrl': null,
    };

final _sara = _member('mock-sara', 'سارة');
final _abdullah = _member('mock-abdullah', 'عبدالله');
final _ummKhalid = _member('mock-umm-khalid', 'أم خالد');
final _fahad = _member('mock-fahad', 'فهد');

final _people = [
  _member('mock-maryam', 'مريم'),
  _member('mock-yousef', 'يوسف'),
  _member('mock-reem', 'ريم'),
  _member('mock-khaled', 'خالد'),
  _member('mock-nour', 'نور'),
  _member('mock-omar', 'عمر'),
];

const _fillers = [
  'جزاكِ الله خيراً على هذا التوضيح.',
  'نفع الله بكِ.',
  'كلام مهم، شكراً لكِ.',
  'هل يمكن نشر المزيد عن هذا الموضوع؟',
  'أتفق معكِ تماماً.',
  'اللهم يسّر لكل الشباب والبنات.',
  'معلومة كنت أحتاجها، بارك الله فيكِ.',
  'تجربتنا كانت مشابهة والحمد لله.',
  'سؤال: هل تكفي الاستخارة مرة واحدة؟',
];
