import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/assigned_matchmaker.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_user_profile.dart';
import 'package:qeran/features/matchmaker/users/presentation/matchmaker_user_profile_args.dart';
import 'package:qeran/features/matchmaker/users/presentation/widgets/matchmaker_profile_contact.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

/// The button used to depend on a NAVIGATION argument, which only the explore
/// list passed — so it appeared from explore and nowhere else, however good
/// the data was. These pin the rule that replaced it.
MatchmakerUserProfile _profile({
  bool isAssignedToMe = false,
  AssignedMatchmaker? assigned,
}) => MatchmakerUserProfile(
  userId: 'u1',
  name: 'مستخدم',
  email: 'a@b.c',
  gender: 'أنثى',
  birthDate: null,
  age: 28,
  profileStatus: ProfileStatus.visible,
  hasAnsweredQuestions: true,
  isAssignedToMe: isAssignedToMe,
  profileImage: null,
  images: const [],
  placements: const [],
  assignedMatchmaker: assigned,
);

const _fetched = AssignedMatchmaker(
  id: 'mm-fetched',
  name: 'أم أحمد',
  imageUrl: null,
  conversationId: 16,
);

const _navArg = ResponsibleMatchmakerContact(
  id: 'mm-nav',
  name: 'من الاستكشاف',
);

void main() {
  // The case that was broken: a chat, a deep link, or the router's bare-id
  // path carries no argument at all.
  test('the fetched matchmaker alone is enough — no nav arg needed', () {
    final contact = profileContact(profile: _profile(assigned: _fetched));

    expect(contact?.id, 'mm-fetched');
  });

  // Explore still paints on the first frame, before its fetch lands.
  test('the nav arg carries the button until the fetch arrives', () {
    final contact = profileContact(profile: _profile(), navArg: _navArg);

    expect(contact?.id, 'mm-nav');
  });

  // One value, one source of truth: whatever the server just said wins.
  test('the fetch replaces the nav arg once both are present', () {
    final contact = profileContact(
      profile: _profile(assigned: _fetched),
      navArg: _navArg,
    );

    expect(contact?.id, 'mm-fetched');
  });

  // "Contact the responsible matchmaker" would mean contacting myself. Checked
  // on the flag rather than trusting the server to null the object.
  test('my own user offers no button, from either source', () {
    expect(
      profileContact(
        profile: _profile(isAssignedToMe: true, assigned: _fetched),
        navArg: _navArg,
      ),
      isNull,
    );
  });

  test('a user with no matchmaker at all offers no button', () {
    expect(profileContact(profile: _profile()), isNull);
  });

  test('the contact carries the name and image the button draws', () {
    final contact = profileContact(
      profile: _profile(
        assigned: const AssignedMatchmaker(
          id: 'mm',
          name: 'أم أحمد',
          imageUrl: 'https://host/img.png',
          conversationId: null,
        ),
      ),
    );

    expect(contact?.name, 'أم أحمد');
    expect(contact?.profileImageUrl, 'https://host/img.png');
  });
}
