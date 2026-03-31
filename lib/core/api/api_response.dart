import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final int? status;
  final T? data;
  final String? message;

  const ApiResponse({this.status, this.data, this.message});

  bool get isSuccess => status == 1;

  @override
  List<Object?> get props => [status, data, message];

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return ApiResponse<T>(
      status: json['status'] as int? ?? 0,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
    );
  }
}