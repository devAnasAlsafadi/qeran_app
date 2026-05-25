import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/domain/entities/success_response.dart';

import '../models/link_device_request_model.dart';
import '../models/register_device_request_model.dart';

abstract interface class DeviceRemoteDataSource {
  Future<SuccessResponse<void>> registerDevice(
    RegisterDeviceRequestModel request,
  );

  Future<SuccessResponse<void>> linkDevice(LinkDeviceRequestModel request);
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const DeviceRemoteDataSourceImpl({required ApiConsumer apiConsumer})
    : _apiConsumer = apiConsumer;

  @override
  Future<SuccessResponse<void>> registerDevice(
    RegisterDeviceRequestModel request,
  ) async {
    final response = await _apiConsumer.post(
      EndPoints.registerDevice,
      body: request.toJson(),
    );
    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<void>> linkDevice(
    LinkDeviceRequestModel request,
  ) async {
    final response = await _apiConsumer.post(
      EndPoints.linkDevice,
      body: request.toJson(),
    );
    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }
}
