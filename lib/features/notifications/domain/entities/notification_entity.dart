import 'package:equatable/equatable.dart';

enum NotificationKind { match, like, message, system }

class NotificationEntity extends Equatable {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String timeAgo;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id, kind, title, body, timeAgo, isRead];
}





