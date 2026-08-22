import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/users/data/models/assigned_matchmaker_model.dart';

/// The server sends this as ONE nested object, not three flat fields — that
/// was a deliberate backend decision, so the parser has to read the shape it
/// actually gets rather than the flat trio explore sends.
void main() {
  test('reads the nested object and renames displayName', () {
    final model = AssignedMatchmakerModel.fromJson({
      'id': 'a5c91826',
      'displayName': 'أم أحمد',
      'imageUrl': '/api/users/profile-images/b8275221',
      'conversationId': 16,
    })!;

    final entity = model.toEntity();
    expect(entity.id, 'a5c91826');
    expect(entity.name, 'أم أحمد');
    expect(entity.conversationId, 16);
  });

  // The wire path is relative and needs the auth header, same as
  // profileImageUrl — the widget layer must never have to know that.
  test('absolutises a relative image path', () {
    final entity = AssignedMatchmakerModel.fromJson({
      'id': 'x',
      'displayName': 'n',
      'imageUrl': '/api/users/profile-images/abc',
    })!.toEntity();

    expect(entity.imageUrl, startsWith('http'));
    expect(entity.imageUrl, endsWith('/api/users/profile-images/abc'));
  });

  // Most matchmakers in production have no photo at all, so this is the
  // COMMON case, not an edge one. It must read as "no image", never as a
  // bare host with an empty path.
  test(
    'a missing or empty image stays null rather than becoming a bare host',
    () {
      final noKey = AssignedMatchmakerModel.fromJson({
        'id': 'x',
        'displayName': 'n',
      })!.toEntity();
      final empty = AssignedMatchmakerModel.fromJson({
        'id': 'x',
        'displayName': 'n',
        'imageUrl': '',
      })!.toEntity();

      expect(noKey.imageUrl, isNull);
      expect(empty.imageUrl, isNull);
    },
  );

  test('a user with no matchmaker parses to null, not an empty contact', () {
    expect(AssignedMatchmakerModel.fromJson(null), isNull);
  });

  // An id-less row would render a button that opens a chat with nobody.
  test('drops a row that cannot name anyone', () {
    expect(
      AssignedMatchmakerModel.fromJson({'displayName': 'no id here'}),
      isNull,
    );
    expect(AssignedMatchmakerModel.fromJson({'id': ''}), isNull);
    expect(AssignedMatchmakerModel.fromJson('not a map'), isNull);
  });

  test('conversationId is optional — null before the two have ever spoken', () {
    final entity = AssignedMatchmakerModel.fromJson({
      'id': 'x',
      'displayName': 'n',
    })!.toEntity();

    expect(entity.conversationId, isNull);
  });
}
