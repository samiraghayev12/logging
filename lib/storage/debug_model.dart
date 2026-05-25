import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DebugModel {
  final int id;
  final RequestOptions requestOptions;
  final DateTime requestStartTime;

  Response? response;
  DioException? dioError;
  DateTime? requestEndTime;
  int? elapsedTime;

  DebugModel({
    required this.id,
    required this.requestOptions,
    required this.requestStartTime,
    this.response,
    this.dioError,
    this.requestEndTime,
    this.elapsedTime,
  });

  // ============ STATUS ============

  bool get hasError {
    if (dioError != null) return true;
    final code = _effectiveResponse?.statusCode;
    if (code == null)
      return response == null && dioError == null ? false : true;
    return code >= 400;
  }

  /// Real response — error halında da əldə edilir
  Response? get _effectiveResponse => response ?? dioError?.response;

  // ============ REQUEST INFO ============

  String get httpMethod => requestOptions.method;
  String get path => requestOptions.path;
  String get url => requestOptions.uri.toString();

  String get timeoutInterval {
    final timeout = requestOptions.connectTimeout;
    return timeout == null ? "NONE" : "${timeout.inMilliseconds} ms";
  }

  Map<String, dynamic> get requestHeaders => requestOptions.headers;
  bool get hasRequestData => requestOptions.data != null;
  dynamic get requestData => requestOptions.data;
  Map<String, dynamic> get queryParameters => requestOptions.queryParameters;
  bool get hasQueryParameters => queryParameters.isNotEmpty;

  // ============ RESPONSE INFO ============

  Map<String, dynamic> get responseHeaders =>
      _effectiveResponse?.headers.map ?? {};
  bool get hasResponseData => _effectiveResponse?.data != null;
  dynamic get responseData => _effectiveResponse?.data;

  String get statusCode {
    final code = _effectiveResponse?.statusCode;
    if (code != null) return "$code";
    // Network error və s. üçün dioError tipindən status göstər
    if (dioError != null) return _errorTypeLabel(dioError!.type);
    return "Pending";
  }

  String get statusMessage {
    final msg = _effectiveResponse?.statusMessage;
    if (msg != null && msg.isNotEmpty) return msg;
    if (dioError != null) return dioError!.message ?? "Unknown error";
    if (response == null) return "No response received";
    return "NONE";
  }

  // ============ ERROR DETAILS ============

  /// Backend response body-dən gələn struktur (məs: {title, status, message})
  Map<String, dynamic>? get _errorBody {
    final data = _effectiveResponse?.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Error status code — backend response body-ni də nəzərə alır
  String get errorStatusCode {
    final code = _effectiveResponse?.statusCode;
    if (code != null) return "$code";

    final body = _errorBody;
    if (body != null) {
      // RFC 7807 problem+json: lowercase "status"
      final status = body['status'] ??
          body['Status'] ??
          body['statusCode'] ??
          body['StatusCode'];
      if (status != null) return "$status";
    }

    if (dioError != null) return _errorTypeLabel(dioError!.type);
    return "Error";
  }

  /// Error mesajı — prioritet ilə backend-dən gələn mesajı götürür
  String get errorStatusMessage {
    final body = _errorBody;

    // 1. Backend response body-də ən informativ field-i tap
    //    Priority: detail > message > title > error_description > error
    if (body != null) {
      final candidates = [
        body['detail'],
        body['Detail'],
        body['message'],
        body['Message'],
        body['error_description'],
        body['errorDescription'],
        body['title'],
        body['Title'],
        body['error'],
        body['Error'],
      ];

      for (final candidate in candidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }

      // Validation errors üçün — {errors: {field: [msg]}}
      final errors = body['errors'] ?? body['Errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return firstField.first.toString();
        }
        if (firstField is String) return firstField;
      }
    }

    // 2. HTTP statusMessage
    final httpMsg = _effectiveResponse?.statusMessage;
    if (httpMsg != null && httpMsg.trim().isNotEmpty) return httpMsg;

    // 3. Dio exception message
    final exceptionMsg = dioError?.message;
    if (exceptionMsg != null && exceptionMsg.trim().isNotEmpty)
      return exceptionMsg;

    // 4. Dio error type
    if (dioError != null) return _errorTypeReadable(dioError!.type);

    return "Unknown error occurred";
  }

  Map<String, dynamic> get errorHeaders =>
      dioError?.response?.headers.map ?? _effectiveResponse?.headers.map ?? {};

  // ============ UI HELPERS ============

  Color get httpMethodColor {
    switch (httpMethod.toUpperCase()) {
      case "GET":
        return Colors.green;
      case "POST":
        return Colors.orange;
      case "PUT":
        return Colors.blueAccent;
      case "PATCH":
        return Colors.purple;
      case "DELETE":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color get statusColor {
    final code = _effectiveResponse?.statusCode;
    if (code == null) return Colors.grey;
    if (code >= 500) return Colors.red.shade700;
    if (code >= 400) return Colors.orange.shade700;
    if (code >= 300) return Colors.blue;
    if (code >= 200) return Colors.green;
    return Colors.grey;
  }

  String get elapsedTimeInMs => elapsedTime != null ? "$elapsedTime ms" : "N/A";

  String get requestTimeString =>
      requestEndTime?.toString() ?? requestStartTime.toString();

  String get requestTime => requestTimeString;

  // ============ INTERNAL ============

  static String _errorTypeLabel(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return "TIMEOUT";
      case DioExceptionType.sendTimeout:
        return "TIMEOUT";
      case DioExceptionType.receiveTimeout:
        return "TIMEOUT";
      case DioExceptionType.badCertificate:
        return "CERT";
      case DioExceptionType.connectionError:
        return "NO_CONN";
      case DioExceptionType.cancel:
        return "CANCELLED";
      case DioExceptionType.unknown:
        return "ERROR";
      case DioExceptionType.badResponse:
        return "ERROR";
    }
  }

  static String _errorTypeReadable(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timeout";
      case DioExceptionType.sendTimeout:
        return "Send timeout";
      case DioExceptionType.receiveTimeout:
        return "Receive timeout";
      case DioExceptionType.badCertificate:
        return "Bad SSL certificate";
      case DioExceptionType.connectionError:
        return "No internet connection";
      case DioExceptionType.cancel:
        return "Request cancelled";
      case DioExceptionType.unknown:
        return "Unknown error";
      case DioExceptionType.badResponse:
        return "Server returned an error";
    }
  }
}
