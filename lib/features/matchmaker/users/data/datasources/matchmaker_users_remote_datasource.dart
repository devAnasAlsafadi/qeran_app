import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../models/matchmaker_users_page_model.dart';
import '../models/subscription_plan_model.dart';

abstract interface class MatchmakerUsersRemoteDataSource {
  Future<MatchmakerUsersPageModel> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
    int? planId,
    Gender? gender,
  });

  /// The dynamic plan list backing the مشتركون plan-filter rail.
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans();
}

class MatchmakerUsersRemoteDataSourceImpl
    implements MatchmakerUsersRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerUsersRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerUsersPageModel> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
    int? planId,
    Gender? gender,
  }) async {
    final path = switch (list) {
      MatchmakerUsersList.pending => EndPoints.matchmakerUsersPending,
      MatchmakerUsersList.approvedUnsubscribed =>
        EndPoints.matchmakerUsersApprovedUnsubscribed,
      MatchmakerUsersList.approvedSubscribed =>
        EndPoints.matchmakerUsersApprovedSubscribed,
    };
    AppLogger.debug(
      'MATCHMAKER — get users ${list.name} page=$page size=$pageSize'
      '${planId == null ? '' : ' planId=$planId'}',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      path,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        // Server-side plan filter — only the subscribed list ever passes it;
        // the null-aware value drops the entry entirely when planId is null.
        'planId': ?planId,
        // Server-side gender filter for the share picker. ⚠️ NOT yet
        // supported by these endpoints — `/matchmaker/explore` has it, but
        // the picker cannot use explore (recipients must be the matchmaker's
        // OWN users). Wired end-to-end and left unset by every caller, so
        // nothing sends it until the backend accepts it.
        'gender': ?gender?.apiValue,
      },
    );
    final apiResponse = ApiResponse<MatchmakerUsersPageModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => MatchmakerUsersPageModel.fromJson(json as Map<String, dynamic>),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — users ${list.name} ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }

  @override
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    AppLogger.debug('MATCHMAKER — get subscription plans', tag: 'MATCHMAKER');
    final response = await _apiConsumer.get(
      EndPoints.matchmakerUsersSubscriptionPlans,
    );
    final apiResponse = ApiResponse<List<SubscriptionPlanModel>>.fromJson(
      response as Map<String, dynamic>,
      (json) => parseMapList(json)
          .map(SubscriptionPlanModel.fromJson)
          .toList(growable: false),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — subscription plans ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }
}
