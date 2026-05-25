import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_info.dart';

/// Sealed state for the chat tab entry. Drives loading vs
/// no-matchmaker vs failure vs ready (which embeds the conversation
/// screen).
sealed class ChatEntryState extends Equatable {
  const ChatEntryState();

  @override
  List<Object?> get props => const [];
}

class ChatEntryInitial extends ChatEntryState {
  const ChatEntryInitial();
}

class ChatEntryLoading extends ChatEntryState {
  const ChatEntryLoading();
}

class ChatEntryNoMatchmaker extends ChatEntryState {
  const ChatEntryNoMatchmaker();
}

class ChatEntryReady extends ChatEntryState {
  final MatchmakerInfo info;
  const ChatEntryReady({required this.info});

  @override
  List<Object?> get props => [info];
}

class ChatEntryFailure extends ChatEntryState {
  const ChatEntryFailure();
}
