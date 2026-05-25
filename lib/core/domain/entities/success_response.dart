import '../../api/api_response.dart';

class SuccessResponse<T> extends ApiResponse<T> {
  const SuccessResponse({super.status, super.data, super.message});

  factory SuccessResponse.fromApiResponse(ApiResponse<T> response) {
    return SuccessResponse<T>(
      status: response.status,
      data: response.data,
      message: response.message,
    );
  }
}
