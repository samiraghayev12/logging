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

  bool get hasError => dioError != null || response == null;

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

  String get statusCode {
    if (response == null) return "Error";
    return "${response?.statusCode}";
  }

  String get statusMessage {
    if (response == null) return "No response received";
    return response?.statusMessage ?? "NONE";
  }

  String get errorStatusCode {
    // Try to get from response statusCode
    if (dioError?.response?.statusCode != null) {
      return "${dioError?.response?.statusCode}";
    }
    // Try to get from response data if it's a map
    final responseData = dioError?.response?.data;
    if (responseData is Map && responseData['Status'] != null) {
      return "${responseData['Status']}";
    }
    return "Error";
  }

  String get errorStatusMessage {
    // Try to get from response statusMessage
    if (dioError?.response?.statusMessage != null) {
      return "${dioError?.response?.statusMessage}";
    }
    // Try to get from response data Title if it's a map
    final responseData = dioError?.response?.data;
    if (responseData is Map) {
      if (responseData['Title'] != null && responseData['Title'].toString().isNotEmpty) {
        return "${responseData['Title']}";
      }
      if (responseData['Message'] != null && responseData['Message'].toString().isNotEmpty) {
        return "${responseData['Message']}";
      }
    }
    // Try to get DIO exception message
    final exceptionMessage = dioError?.message;
    if (exceptionMessage != null && exceptionMessage.toString().isNotEmpty) {
      return exceptionMessage.toString();
    }
    return "Unknown error occurred";
  }

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
