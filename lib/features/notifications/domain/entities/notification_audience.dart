import 'package:equatable/equatable.dart';

/// Who a notification was written for, read from the wire `data.audience`.
///
/// One event can be pushed to several people at once — the compatibility-case
/// update goes to the matchmaker AND to both members — so the payload names
/// its reader. Without it, a shell acts on a notification meant for someone
/// else.
///
/// ⚠️ A value WRAPPER, not an enum, and the shape is the design. Only ONE
/// value has ever been confirmed against a real backend payload
/// ([matchmakerValue]); the formal step will add more, for the two members who
/// receive the same accepted-step event and should not read it identically.
/// Those names are the SERVER's to choose and are not yet given, so nothing
/// here invents them.
///
/// An enum would have to. Its `unknown` member folds together the two states
/// this type keeps apart — [isAbsent], nobody was named, and [isUnrecognised],
/// someone was named that this build does not know — and the second is exactly
/// the state a not-yet-taught value arrives in. Collapsing them would make a
/// new server audience indistinguishable from a payload that carried none,
/// which is the difference between "this is not for me" and "I cannot tell".
///
/// When the names arrive they become two more predicates beside [isMatchmaker]
/// and nothing already written changes.
class NotificationAudience extends Equatable {
  const NotificationAudience._(this.raw);

  /// The wire value, trimmed and lowercased; empty when the payload named
  /// nobody.
  ///
  /// Kept verbatim rather than folded into a known set, so a value this build
  /// has not been taught survives the trip and can be read by whoever learns
  /// it first.
  final String raw;

  /// The payload carried no audience at all.
  ///
  /// The common case, and it must stay harmless: every notification that
  /// predates the field, and every one the server does not target, arrives
  /// this way.
  static const NotificationAudience absent = NotificationAudience._('');

  /// The one value confirmed against a real backend payload.
  static const String matchmakerValue = 'matchmaker';

  /// Never throws, whatever the wire sends. A non-string value becomes its
  /// own text and lands in [isUnrecognised] rather than being dropped —
  /// unreadable is a different thing from missing, here as everywhere else in
  /// this feature.
  static NotificationAudience fromWire(Object? raw) {
    final value = (raw?.toString() ?? '').trim().toLowerCase();
    return value.isEmpty ? absent : NotificationAudience._(value);
  }

  bool get isAbsent => raw.isEmpty;

  bool get isMatchmaker => raw == matchmakerValue;

  /// Named, but not by a name this build knows.
  ///
  /// Deliberately NOT `!isMatchmaker`. That would swallow [isAbsent], and the
  /// two mean opposite things to a caller deciding whether to act: an absent
  /// audience is an untargeted notification, an unrecognised one is a
  /// notification aimed at somebody in particular that this build cannot
  /// place.
  bool get isUnrecognised => !isAbsent && !isMatchmaker;

  @override
  List<Object?> get props => [raw];
}
