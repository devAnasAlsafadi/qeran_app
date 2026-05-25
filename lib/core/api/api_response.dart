import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final int? status;
  final T? data;
  final String? message;

  /// Optional machine-readable error identifier the backend now ships on
  /// failure envelopes (e.g. `SUBSCRIPTION_REQUIRED`, `LIKE_EXPIRED`).
  /// Used by data-source classifiers in preference to Arabic message
  /// substring matching; absent on legacy responses.
  final String? errorCode;

  const ApiResponse({this.status, this.data, this.message, this.errorCode});

  bool get isSuccess => status == 1;

  @override
  List<Object?> get props => [status, data, message, errorCode];

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] as int? ?? 0,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
    );
  }
}
