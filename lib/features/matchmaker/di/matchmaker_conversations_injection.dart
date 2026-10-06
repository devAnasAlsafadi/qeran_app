import 'package:qeran/core/di/injection_container.dart';

import '../colleagues/data/datasources/matchmaker_colleagues_remote_datasource.dart';
import '../colleagues/data/repositories/matchmaker_colleagues_repository_impl.dart';
import '../colleagues/domain/repositories/matchmaker_colleagues_repository.dart';
import '../colleagues/domain/usecases/get_colleague_conversations_usecase.dart';
import '../colleagues/domain/usecases/get_colleagues_usecase.dart';
import '../colleagues/domain/usecases/open_colleague_chat_usecase.dart';
import '../colleagues/presentation/blocs/matchmaker_colleague_conversations_cubit.dart';
import '../colleagues/presentation/blocs/matchmaker_colleague_open_chat_cubit.dart';
import '../conversations/data/datasources/matchmaker_conversations_remote_datasource.dart';
import '../conversations/data/repositories/matchmaker_conversations_repository_impl.dart';
import '../conversations/domain/repositories/matchmaker_conversations_repository.dart';
import '../conversations/domain/usecases/get_user_conversations_usecase.dart';
import '../conversations/domain/usecases/open_user_chat_usecase.dart';
import '../conversations/presentation/blocs/matchmaker_open_chat_cubit.dart';
import '../conversations/presentation/blocs/matchmaker_user_conversations_cubit.dart';

/// Her conversations: with users, and with colleagues.
/// Called by [initMatchmakerDependencies].
void initMatchmakerConversationsDependencies() {
  //! ── M4a · Conversations (with users) ─────────────────────────────
  sl.registerLazySingleton<MatchmakerConversationsRemoteDataSource>(
    () => MatchmakerConversationsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerConversationsRepository>(
    () => MatchmakerConversationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetUserConversationsUseCase(sl()));
  sl.registerLazySingleton(() => OpenUserChatUseCase(sl()));
  // One open-chat cubit per user list (M3c) — resolves the lazy
  // /matchmaker/users/{id}/chat conversation, then the host navigates with it.
  sl.registerFactory(() => MatchmakerOpenChatCubit(openUserChat: sl()));
  // One cubit per conversations tab mount — the caller passes the current
  // user's id (from UserSessionCubit) via param1 so self-sent live messages
  // don't bump unread. The realtime port (4c-1) is reused.
  sl.registerFactoryParam<MatchmakerUserConversationsCubit, String, void>(
    (myUserId, _) => MatchmakerUserConversationsCubit(
      getConversations: sl(),
      realtimePort: sl(),
      myUserId: myUserId,
    ),
  );

  //! ── S2a · Colleagues (directory + colleague conversations) ───────
  // Data/domain only here; the colleague-conversations list + directory UI
  // and their cubits are wired in S2b/S2c. The colleague chat reuses the
  // shared MatchmakerUserChatScreen (the MatchmakerConversation entity is
  // generic), and the "start chat" action reuses the open-chat→navigate host.
  sl.registerLazySingleton<MatchmakerColleaguesRemoteDataSource>(
    () => MatchmakerColleaguesRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerColleaguesRepository>(
    () => MatchmakerColleaguesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetColleaguesUseCase(sl()));
  sl.registerLazySingleton(() => GetColleagueConversationsUseCase(sl()));
  sl.registerLazySingleton(() => OpenColleagueChatUseCase(sl()));
  // S2b · colleague-conversations segment — one cubit per mount; the caller
  // passes the current user's id (param1) so self-sent live messages don't
  // bump unread. Reuses the shared realtime port (4c-1).
  sl.registerFactoryParam<MatchmakerColleagueConversationsCubit, String, void>(
    (myUserId, _) => MatchmakerColleagueConversationsCubit(
      getConversations: sl(),
      realtimePort: sl(),
      myUserId: myUserId,
    ),
  );
  // S2b · resolves a colleague's conversation before navigating to chat.
  sl.registerFactory(
    () => MatchmakerColleagueOpenChatCubit(openColleagueChat: sl()),
  );
}
