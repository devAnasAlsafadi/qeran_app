import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../data/datasources/chat_realtime_signalr_service.dart';
import '../data/datasources/chat_remote_datasource.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/ports/chat_realtime_port.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/get_conversation_messages_usecase.dart';
import '../domain/usecases/get_conversations_usecase.dart';
import '../domain/usecases/get_my_matchmaker_usecase.dart';
import '../domain/usecases/mark_conversation_as_read_usecase.dart';
import '../domain/usecases/send_text_message_usecase.dart';
import '../domain/usecases/share_profile_usecase.dart';
import '../presentation/blocs/chat_entry_cubit.dart';
import '../presentation/blocs/chat_unread_cubit.dart';
import '../presentation/blocs/conversation_cubit.dart';

/// Wire the chat feature into the global DI container. The realtime
/// port is registered as a lazy singleton — there's exactly one
/// SignalR connection per app lifetime; Phase 8 connects/disconnects
/// it from `ConversationCubit`'s lifecycle.
void initChatDependencies() {
  //! DataSources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Realtime (SignalR) — receive-only by design. Lazy singleton so
  //  the same HubConnection is reused across screen mounts.
  sl.registerLazySingleton<ChatRealtimePort>(
    () => ChatRealtimeSignalRService(),
  );

  //! Read fresh from secure storage on every connect AND every reconnect —
  //  once a refresh-token flow lands, swapping the stored value is the only
  //  change the realtime layer needs. Registered rather than hand-rolled at
  //  each shell so the two can never read the token differently.
  sl.registerLazySingleton<ChatAccessTokenProvider>(
    () =>
        () => sl<StorageService>().get<String>(StorageKeys.token),
  );

  //! Repository
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));

  //! UseCases
  sl.registerLazySingleton(() => GetMyMatchmakerUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendTextMessageUseCase(sl()));
  sl.registerLazySingleton(() => ShareProfileUseCase(sl()));
  sl.registerLazySingleton(() => MarkConversationAsReadUseCase(sl()));

  //! Cubits (screen-scoped)
  sl.registerFactory(() => ChatEntryCubit(getMyMatchmaker: sl()));

  //! App-scoped unread badge used by the home navigation.
  sl.registerLazySingleton(() => ChatUnreadCubit(getConversations: sl()));

  //! Parametrised — caller provides `(conversationId, myUserId)` per
  //  screen mount. `myUserId` is the current user's id (read from
  //  `UserSessionCubit` by the screen) and is used to stamp
  //  optimistic temps' `senderId` so the UI's isMine logic agrees.
  sl.registerFactoryParam<ConversationCubit, int, String>(
    (conversationId, myUserId) => ConversationCubit(
      conversationId: conversationId,
      myUserId: myUserId,
      getMessages: sl(),
      markAsRead: sl(),
      sendText: sl(),
      shareProfile: sl(),
      realtimePort: sl(),
    ),
  );
}
