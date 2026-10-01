/// The mock's config and guidelines, as the server sends them.
library;

/// Tariq's built values (`05-backend-response.md` §3).
Map<String, dynamic> communityMockConfig() => {
      'commentMaxLength': 500,
      'postTextMaxLength': 2000,
      'maxImagesPerPost': 10,
      'maxImageSizeBytes': 5242880,
      'allowedImageTypes': ['jpg', 'jpeg', 'png'],
      'allowedVideoTypes': ['mp4', 'mov'],
      'maxVideoDurationSeconds': 60,
      'maxVideoSizeBytes': 104857600,
      'videoTarget': {'maxHeight': 1280, 'bitrateKbps': 2500, 'codec': 'h264'},
      'videoEnabled': true,
    };

const int communityMockGuidelinesVersion = 1;

/// The board's member text with your fix («من قائمة الخيارات»), under the
/// board's icon names — the live server's text and icons differ (K1, X6).
Map<String, dynamic> communityMockGuidelines() => {
      'version': communityMockGuidelinesVersion,
      'lastUpdatedAt': '2026-10-01T09:00:00Z',
      'introAr':
          'المجتمع مساحة لإرشادات خطّابات قِران ولنقاشٍ محترم حولها. قبل تعليقك الأول، نطلب منك الموافقة على هذه الإرشادات.',
      'introEn':
          'Community is a space for guidance from Qeran’s matchmakers and respectful discussion around it. Before your first comment, please agree to these guidelines.',
      'sections': [
        for (var i = 0; i < _sections.length; i++)
          {
            'id': i + 1,
            'icon': _sections[i].$1,
            'titleAr': _sections[i].$2,
            'bodyAr': _sections[i].$3,
            'titleEn': _sections[i].$4,
            'bodyEn': _sections[i].$5,
          },
      ],
    };

const _sections = [
  (
    'handshake',
    'تحدّث باحترام',
    'تُمنع الإساءة والسخرية والتنمّر والتحرّش تجاه أي عضو أو خطّابة.',
    'Speak respectfully',
    'No insults, mockery, bullying or harassment toward any member or matchmaker.',
  ),
  (
    'phone_disabled',
    'لا معلومات تواصل',
    'لا تشارك أرقام هواتف أو حسابات أو روابط، ولا تطلبها من أحد. التواصل يتم عبر خطّابتك فقط.',
    'No contact details',
    'Don’t share or ask for phone numbers, accounts or links. Contact happens only through your matchmaker.',
  ),
  (
    'gpp_bad',
    'محتوى لائق فقط',
    'يُمنع المحتوى الفاحش، والمسيء دينياً أو عنصرياً، والإعلانات.',
    'Appropriate content only',
    'No obscene, religiously or racially offensive content, and no advertising.',
  ),
  (
    'person_off',
    'احفظ خصوصية الآخرين',
    'لا تذكر أسماء أو تفاصيل تكشف هوية أي شخص.',
    'Protect others’ privacy',
    'Don’t mention names or details that reveal anyone’s identity.',
  ),
  (
    'flag',
    'البلاغ والحذف',
    'أبلغ عن أي مخالفة من قائمة الخيارات. قد تُحذف المخالفات دون إشعار، وقد يُمنع صاحبها من التعليق.',
    'Reporting and removal',
    'Report anything that breaks these rules from the options menu. Violations may be removed without notice, and the author may lose the ability to comment.',
  ),
];
