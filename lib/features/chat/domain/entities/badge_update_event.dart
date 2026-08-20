import 'package:equatable/equatable.dart';

/// SignalR `BadgeUpdated` payload — `{ tab, count }`.
///
/// Not a chat event. It rides the chat hub because that connection belongs to
/// the app rather than to any chat screen: both shells hold one open for their
/// whole lifetime, so an event arriving here reaches every tab. It is declared
/// beside the chat events for the same reason the port carries it — the badges
/// feature listens to chat's port, and keeping the type here leaves that
/// dependency running one way.
///
/// [count] is ABSOLUTE — what the total now is, never a delta. Consumers assign
/// it; adding would double whatever a REST refresh had already counted.
class BadgeUpdateEvent extends Equatable {
  final String tab;
  final int count;

  const BadgeUpdateEvent({required this.tab, required this.count});

  @override
  List<Object?> get props => [tab, count];
}
