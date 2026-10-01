import 'community_mock_records.dart';
import 'community_mock_seed_comments.dart';

/// The mock's starting data: the board's posts (istikhara, questions with
/// four images, a video, the long text, the kunya author, one English post —
/// D13) by three matchmakers, then fillers to make two feed pages. Media are
/// Flutter's own documentation assets (Q1) — absolute, so they never get our
/// token. Dev builds only; tests use it as a realistic fake.
class CommunityMockSeed {
  final List<MockPost> posts;
  final List<MockComment> comments;

  const CommunityMockSeed({required this.posts, required this.comments});

  factory CommunityMockSeed.build(
    DateTime now, {
    required CommunityMockViewer viewer,
    bool empty = false,
  }) {
    if (empty) return const CommunityMockSeed(posts: [], comments: []);
    final posts = _posts(now);
    return CommunityMockSeed(
      posts: posts,
      comments: seedComments(now, firstPostId: posts.first.id, viewer: viewer),
    );
  }

  static const _docs = 'https://flutter.github.io/assets-for-api-docs/assets';

  static const huda = {
    'id': 'mock-mm-huda',
    'displayName': 'هدى العتيبي',
    'isMatchmaker': true,
    'profileImageUrl': null,
  };
  static const noura = {
    'id': 'mock-mm-noura',
    'displayName': 'نورة الدوسري',
    'isMatchmaker': true,
    'profileImageUrl': '$_docs/widgets/owl-3.jpg',
  };
  static const umm = {
    'id': 'mock-mm-umm',
    'displayName': 'أم عبدالرحمن الشمّري',
    'isMatchmaker': true,
    'profileImageUrl': null,
  };

  static Map<String, dynamic> _image(String name, int w, int h) => {
        'type': 'Image',
        'url': '$_docs/widgets/$name',
        'thumbnailUrl': null,
        'width': w,
        'height': h,
      };

  static List<MockPost> _posts(DateTime now) {
    final board = <(Map<String, dynamic>, String, List<Map<String, dynamic>>, int)>[
      (huda, _istikhara, const [], 128),
      (noura, _questions, [
        _image('owl.jpg', 1080, 1080),
        _image('owl-2.jpg', 1080, 1080),
        _image('owl-3.jpg', 1080, 1080),
        _image('owl.jpg', 1080, 1080),
      ], 46),
      (huda, _videoText, [_video(now)], 23),
      (umm, _long, const [], 1240),
      (noura, _fillers[0], [_image('owl-2.jpg', 1600, 1067)], 9),
      (huda, _english, const [], 3),
      (umm, _kunya, const [], 0),
    ];
    final authors = [huda, noura, umm];
    final rows = [
      ...board,
      for (var i = 1; i < _fillers.length; i++)
        (authors[i % 3], _fillers[i], const <Map<String, dynamic>>[], i * 3),
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        MockPost(
          id: 1000 + rows.length - i,
          author: rows[i].$1,
          text: rows[i].$2,
          media: rows[i].$3,
          likeCount: rows[i].$4,
          likedByMe: i == 0,
          publishedAt: now.subtract(Duration(hours: 1 + i * 7)),
        ),
    ];
  }

  /// The real clip's length may differ from `durationSeconds` — dev only.
  static Map<String, dynamic> _video(DateTime now) => {
        'type': 'Video',
        'url': '$_docs/videos/butterfly.mp4',
        'posterUrl': null,
        'hlsUrl': null,
        'width': 1280,
        'height': 720,
        'durationSeconds': 52,
        'urlExpiresAt': now.add(const Duration(hours: 6)).toIso8601String(),
      };

  static const _istikhara =
      'الاستخارة لا تعني انتظار رؤيا أو علامة. صلِّ ركعتين وادعُ بدعاء الاستخارة، ثم امضِ في الأمر بالأسباب المعتادة: السؤال عن الخاطب، والاستشارة، والرؤية الشرعية.';
  static const _questions =
      'أسئلة تستحق أن تُطرح في الجلسة الأولى مع أهل الخاطب، جمعناها لكم في هذه البطاقات.';
  static const _videoText =
      'كيف تحدّث أهلك عن رغبتك في الزواج؟ في هذا المقطع أشارك خطوات عملية من تجربتي مع العائلات.';
  static const _long =
      'كثيراً ما يسألني الأهل: متى نعرف أن الوقت مناسب للرؤية الشرعية؟ والجواب أن الرؤية تأتي بعد أن تطمئنّوا إلى الدين والخلق من خلال السؤال والتحرّي، لا قبل ذلك. اجعلوا الخطّابة وسيطاً في ترتيب الموعد، واحرصوا على حضور المحرم، وتذكّروا أن الهدف هو الاطمئنان لا الحكم السريع. وبعد الرؤية امنحوا أنفسكم وقتاً كافياً للتفكير والاستخارة قبل الرد، فلا حرج في طلب مهلة، ولا حرج في الاعتذار بلطف.';
  static const _kunya =
      'تذكير: الصدق في البيانات من البداية يختصر على الطرفين الكثير. راجعوا ملفاتكم قبل أن نبدأ الترشيح.';
  static const _english =
      'A reminder for families: agree on the next step before the first sitting ends, so no one is left waiting for an answer.';

  static const _fillers = [
    'الخِطبة وعدٌ بالزواج وليست عقداً، فحافظوا على الحدود الشرعية في هذه المرحلة حتى يتمّ العقد.',
    'لا بأس أن يطول التعارف قليلاً إن كان بالضوابط وبحضور الأهل؛ العجلة في القرار تكلّف كثيراً بعده.',
    'حدّدوا مع أهلكم قبل الجلسة ما الذي لا يمكن التنازل عنه، وما الذي يقبل النقاش.',
    'المهر حقّ للزوجة، والتيسير فيه سنّة. اتفقوا عليه بوضوح ومن غير مبالغة.',
    'إن ترددتم بعد الرؤية الشرعية فاطلبوا مهلة للتفكير، ولا تشعروا بالحرج من ذلك.',
    'اختلاف المدينة ليس عائقاً دائماً، لكن اتفقوا مبكراً على مكان السكن بعد الزواج.',
    'من حق الطرفين السؤال عن الحالة الصحية بأدب، والأفضل أن يكون ذلك عن طريق الخطّابة.',
    'اكتبوا في ملفاتكم ما تبحثون عنه فعلاً، لا ما تظنون أنه يعجب الآخرين.',
    'استشيروا من تثقون بدينه ورأيه، ولا توسّعوا دائرة الحديث قبل أن يتضح الأمر.',
    'إذا لم يحصل التوافق فاعتذروا بلطف ودون تفاصيل جارحة؛ فالكلمة الطيبة تبقى.',
    'تأكدوا من فهم الطرفين لتوقعات العمل بعد الزواج، فهي من أكثر نقاط الخلاف لاحقاً.',
    'لا تقارنوا قصتكم بقصص غيركم؛ لكل بيت ظروفه وتوقيته.',
    'اسألوا عن علاقة الخاطب بوالديه؛ فهي مرآة لكثير من أخلاقه.',
    'تكاليف الزواج تُناقش بصراحة من البداية حتى لا تتحول إلى عبء بعد العقد.',
    'الدعاء بالتوفيق لا يتوقف عند الاستخارة؛ ادعوا لأنفسكم ولمن تتقدمون له.',
    'إن شعرتم بضغط من أحد لاتخاذ القرار بسرعة فتوقفوا وخذوا وقتكم.',
    'الوضوح في الحديث عن الأبناء وتربيتهم يوفّر خلافات كثيرة لاحقاً.',
    'بعض الأسئلة تُطرح في الجلسة الأولى، وبعضها يُترك لما بعدها؛ رتّبوها مع خطّابتكم.',
    'اسألوا عن الصلاة قبل أن تسألوا عن الراتب، فهي أول ما يُطمأنّ إليه.',
    'الصورة الأولى لا تكفي للحكم؛ الأخلاق والدين يظهران في التعامل والسؤال.',
  ];
}
