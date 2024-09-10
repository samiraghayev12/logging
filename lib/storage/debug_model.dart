import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DebugModel {
  int? id;
  RequestOptions? requestOptions;
  Response? response;
  DioException? dioError;
  DateTime? requestStartTime;
  DateTime? requestEndTime;
  String? requestTime;
  int? elapsedTime;

  DebugModel({
    this.id,
    this.requestOptions,
    this.response,
    this.requestTime,
    this.dioError,
    this.requestStartTime,
    this.requestEndTime,
    this.elapsedTime,
  });

  bool get hasError => dioError != null;

  String get httpMethod => requestOptions?.method ?? "NONE";

  String get path => requestOptions?.path ?? "NONE";

  String get url => requestOptions?.uri.toString() ?? "NONE";

  String get timeoutInterval => "${requestOptions?.connectTimeout ?? "NONE"}";

  Map<String, dynamic> get requestHeaders => requestOptions?.headers ?? {};

  Map<String, dynamic> get responseHeaders => response?.headers.map ?? {};

  bool get hasRequestData => requestOptions?.data != null;

  bool get hasResponseData => response?.data != null;

  String get requestTimeString => requestTime ?? "";

  dynamic get responseData => response?.data;

  dynamic get requestData => requestOptions?.data;

  String get statusCode => "${response?.statusCode}";

  String get statusMessage => response?.statusMessage ?? "NONE";

  String get errorStatusCode => "${dioError?.response?.statusCode}";

  String get errorStatusMessage => "${dioError?.response?.statusMessage}";

  Map<String, dynamic> get errorHeaders => dioError?.response?.headers.map ?? {};

  Color get httpMethodColor {
    if (httpMethod == "GET") {
      return Colors.green;
    } else if (httpMethod == "POST") {
      return Colors.orange;
    } else if (httpMethod == "PUT") {
      return Colors.blueAccent;
    } else if (httpMethod == "DELETE") {
      return Colors.red;
    }
    return Colors.black;
  }

  /// Returns the elapsed time for the request in milliseconds
  String get elapsedTimeInMs => elapsedTime != null ? "$elapsedTime ms" : "N/A";
}
