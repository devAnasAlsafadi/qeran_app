import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable{
  final bool? status;
  final T? data;
  final String? message;


  const ApiResponse({this.status, this.data, this.message});

  @override
  List<Object?> get props => [status, data, message];


  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return ApiResponse<T>(
      status: json['status'] as bool?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
    );
  }


}