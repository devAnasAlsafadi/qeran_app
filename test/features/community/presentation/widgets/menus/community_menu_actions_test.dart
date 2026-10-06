import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_actions.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import '../../../fixtures/community_post_fixtures.dart';

/// The ⋮ rows come from the server's flags (E1–E4, I1), with one rule of
/// the app's own: never Block for a matchmaker (D40).
void main() {
  const member = CommunityViewer.member;
  const matchmaker = CommunityViewer.matchmaker;
  const delete = CommunityMenuAction.delete;
  const report = CommunityMenuAction.report;
  const block = CommunityMenuAction.block;

  test('E1: a post offers Report — her own post, Delete only (B6)', () {
    expect(postMenuActions(testPost()), [report]);
    expect(postMenuActions(testPost(canDelete: true)), [delete]);
  });

  test("E2: someone's comment — Report, then Block", () {
    expect(commentMenuActions(testComment(), member), [report, block]);
  });

  test('E3: my own comment — Delete only', () {
    final mine = testComment(isMine: true, canDelete: true);

    expect(commentMenuActions(mine, member), [delete]);
  });

  test("E4: a matchmaker's reply — Report only (the server says no Block)", () {
    final reply = testReply(author: huda);

    expect(commentMenuActions(reply, member), [report]);
  });

  test("I1: on her post, a member's comment — Delete and Report, never "
      'Block, whatever the flag says (D40)', () {
    final comment = testComment(canDelete: true, canBlock: true);

    expect(commentMenuActions(comment, matchmaker), [delete, report]);
  });

  test('what a row names: a reply, or a comment', () {
    expect(contentKindOf(testReply()), ReportContentKind.reply);
    expect(contentKindOf(testComment()), ReportContentKind.comment);
  });
}
