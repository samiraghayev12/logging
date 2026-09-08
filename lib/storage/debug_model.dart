import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../utils/log_formatter.dart';

/// Sorğunun ümumi vəziyyəti.
enum DebugStatus { pending, success, redirect, clientError, serverError, failed }

class DebugModel {
  final int id;
  final RequestOptions requestOptions;
  final DateTime requestStartTime;

  Response<dynamic>? response;
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

  /// Cavab (və ya error cavabı) hələ gəlməyibsə `true`.
  bool get isPending =>
      response == null && dioError == null && requestEndTime == null;

  bool get hasError {
    if (isPending) return false;
    if (dioError != null) return true;
    final code = statusCodeValue;
    if (code == null) return true;
    return code >= 400;
  }

  bool get isSuccess => !isPending && !hasError;

  DebugStatus get status {
    if (isPending) return DebugStatus.pending;
    final code = statusCodeValue;
    if (code == null) return DebugStatus.failed;
    if (code >= 500) return DebugStatus.serverError;
    if (code >= 400) return DebugStatus.clientError;
    if (code >= 300) return DebugStatus.redirect;
    return DebugStatus.success;
  }

  String get statusLabel {
    switch (status) {
      case DebugStatus.pending:
        return 'Pending';
      case DebugStatus.success:
        return 'Success';
      case DebugStatus.redirect:
        return 'Redirect';
      case DebugStatus.clientError:
        return 'Client Error';
      case DebugStatus.serverError:
        return 'Server Error';
      case DebugStatus.failed:
        return 'Failed';
    }
  }

  /// Real cavab — error halında da əldə edilir.
  Response<dynamic>? get _effectiveResponse => response ?? dioError?.response;

  int? get statusCodeValue => _effectiveResponse?.statusCode;

  // ============ REQUEST INFO ============

  String get httpMethod => requestOptions.method.toUpperCase();

  String get path => requestOptions.path.isEmpty ? uri.path : requestOptions.path;

  Uri get uri => requestOptions.uri;

  String get url => uri.toString();

  String get host => uri.host;

  /// Siyahıda göstərmək üçün qısa yol (query-siz).
  String get shortPath {
    final value = uri.path;
    return value.isEmpty ? '/' : value;
  }

  String get timeoutInterval {
    final timeout = requestOptions.connectTimeout;
    return timeout == null ? 'NONE' : '${timeout.inMilliseconds} ms';
  }

  Map<String, dynamic> get requestHeaders => requestOptions.headers;

  Map<String, String> requestHeadersView({bool redact = false}) =>
      LogFormatter.normalizeHeaders(requestHeaders, redact: redact);

  bool get hasRequestData => requestOptions.data != null;
  dynamic get requestData => requestOptions.data;

  bool get isFormDataRequest => requestData is FormData;

  /// JSON viewer-in göstərə biləcəyi struktur (FormData da daxil).
  Object? get requestDataForView => LogFormatter.forJsonView(requestData);

  Map<String, dynamic> get queryParameters => requestOptions.queryParameters;
  bool get hasQueryParameters => queryParameters.isNotEmpty;

  int? get requestSize => LogFormatter.byteSize(requestData);

  String get requestSizeLabel {
    final size = requestSize;
    return size == null ? '—' : LogFormatter.humanBytes(size);
  }

  String get contentType =>
      '${requestOptions.contentType ?? requestHeaders['content-type'] ?? '—'}';

  // ============ RESPONSE INFO ============

  Map<String, dynamic> get responseHeaders => _effectiveResponse?.headers.map ?? const {};

  Map<String, String> responseHeadersView({bool redact = false}) =>
      LogFormatter.normalizeHeaders(responseHeaders, redact: redact);

  bool get hasResponseData => _effectiveResponse?.data != null;
  dynamic get responseData => _effectiveResponse?.data;

  Object? get responseDataForView => LogFormatter.forJsonView(responseData);

  int? get responseSize {
    final headerValue = _effectiveResponse?.headers.value('content-length');
    final parsed = headerValue == null ? null : int.tryParse(headerValue);
    return parsed ?? LogFormatter.byteSize(responseData);
  }

  String get responseSizeLabel {
    final size = responseSize;
    return size == null ? '—' : LogFormatter.humanBytes(size);
  }

  String get statusCode {
    final code = statusCodeValue;
    if (code != null) return '$code';
    if (dioError != null) return _errorTypeLabel(dioError!.type);
    return 'Pending';
  }

  String get statusMessage {
    final msg = _effectiveResponse?.statusMessage;
    if (msg != null && msg.isNotEmpty) return msg;
    if (dioError != null) return dioError!.message ?? _errorTypeReadable(dioError!.type);
    if (isPending) return 'Waiting for response…';
    if (response == null) return 'No response received';
    return 'NONE';
  }

  // ============ ERROR DETAILS ============

  /// Backend response body-dən gələn struktur (məs: {title, status, message}).
  Map<String, dynamic>? get _errorBody {
    final data = _effectiveResponse?.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = LogFormatter.tryDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  /// Error status code — backend response body-ni də nəzərə alır.
  String get errorStatusCode {
    final code = statusCodeValue;
    if (code != null) return '$code';

    final body = _errorBody;
    if (body != null) {
      // RFC 7807 problem+json
      final status = body['status'] ??
          body['Status'] ??
          body['statusCode'] ??
          body['StatusCode'];
      if (status != null) return '$status';
    }

    if (dioError != null) return _errorTypeLabel(dioError!.type);
    return 'Error';
  }

  /// Error mesajı — prioritetlə backend-dən gələn mesajı götürür.
  String get errorStatusMessage {
    final body = _errorBody;

    // 1. Backend response body-də ən informativ field
    if (body != null) {
      const keys = [
        'detail',
        'Detail',
        'message',
        'Message',
        'error_description',
        'errorDescription',
        'title',
        'Title',
        'error',
        'Error',
      ];
      for (final key in keys) {
        final candidate = body[key];
        if (candidate is String && candidate.trim().isNotEmpty) return candidate;
      }

      // Validation errors — {errors: {field: [msg]}}
      final errors = body['errors'] ?? body['Errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return '${firstField.first}';
        }
        if (firstField is String) return firstField;
      }
    }

    // 2. Body sadəcə mətndirsə
    final rawData = _effectiveResponse?.data;
    if (rawData is String && rawData.trim().isNotEmpty && body == null) {
      return rawData.trim();
    }

    // 3. HTTP statusMessage
    final httpMsg = _effectiveResponse?.statusMessage;
    if (httpMsg != null && httpMsg.trim().isNotEmpty) return httpMsg;

    // 4. Dio exception message
    final exceptionMsg = dioError?.message;
    if (exceptionMsg != null && exceptionMsg.trim().isNotEmpty) return exceptionMsg;

    // 5. Dio error type
    if (dioError != null) return _errorTypeReadable(dioError!.type);

    return 'Unknown error occurred';
  }

  /// Şəbəkə səviyyəsində baş verən xəta (`SocketException` və s.).
  String? get underlyingError {
    final error = dioError?.error;
    return error == null ? null : '$error';
  }

  Map<String, dynamic> get errorHeaders =>
      dioError?.response?.headers.map ?? _effectiveResponse?.headers.map ?? const {};

  Map<String, String> errorHeadersView({bool redact = false}) =>
      LogFormatter.normalizeHeaders(errorHeaders, redact: redact);

  // ============ SEARCH ============

  /// Sorğu tamamlandıqca dəyişdiyi üçün hər dəfə yenidən qurulur.
  String get searchIndex =>
      '$httpMethod $url $statusCode $statusLabel'.toLowerCase();

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return searchIndex.contains(normalized);
  }

  // ============ UI HELPERS ============

  Color get httpMethodColor {
    switch (httpMethod) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.orange;
      case 'PUT':
        return Colors.blueAccent;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      case 'HEAD':
      case 'OPTIONS':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color get statusColor {
    switch (status) {
      case DebugStatus.pending:
        return Colors.blueGrey;
      case DebugStatus.success:
        return Colors.green;
      case DebugStatus.redirect:
        return Colors.blue;
      case DebugStatus.clientError:
        return Colors.orange.shade700;
      case DebugStatus.serverError:
        return Colors.red.shade700;
      case DebugStatus.failed:
        return Colors.red;
    }
  }

  String get elapsedTimeInMs => elapsedTime != null ? '$elapsedTime ms' : '—';

  /// Sürət göstəricisi rəngi.
  Color get durationColor {
    final value = elapsedTime;
    if (value == null) return Colors.grey;
    if (value > 3000) return Colors.red;
    if (value > 1000) return Colors.orange;
    return Colors.green;
  }

  String get requestTimeString => LogFormatter.dateTimeLabel(requestStartTime);

  String get requestTime => requestTimeString;

  /// Siyahı üçün qısa vaxt — `14:32:07.482`.
  String get startClockLabel => LogFormatter.clockTime(requestStartTime);

  Map<String, dynamic> toJson({bool redact = false}) => <String, dynamic>{
        'id': id,
        'method': httpMethod,
        'url': url,
        'status': statusCode,
        'statusLabel': statusLabel,
        'startedAt': requestStartTime.toIso8601String(),
        'finishedAt': requestEndTime?.toIso8601String(),
        'elapsedMs': elapsedTime,
        'requestHeaders': requestHeadersView(redact: redact),
        'queryParameters': LogFormatter.sanitize(queryParameters),
        'requestBody': LogFormatter.sanitize(requestData),
        'responseHeaders': responseHeadersView(redact: redact),
        'responseBody': LogFormatter.sanitize(responseData),
        if (hasError) 'error': errorStatusMessage,
        if (underlyingError != null) 'underlyingError': underlyingError,
      };

  // ============ INTERNAL ============

  // `default` qəsdən var: `DioExceptionType`-a yeni dio versiyalarında
  // dəyər əlavə olunur (məs. `transformTimeout`) və exhaustive switch sınır.
  static String _errorTypeLabel(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT';
      case DioExceptionType.badCertificate:
        return 'CERT';
      case DioExceptionType.connectionError:
        return 'NO_CONN';
      case DioExceptionType.cancel:
        return 'CANCELLED';
      default:
        return type.name.toUpperCase().contains('TIMEOUT') ? 'TIMEOUT' : 'ERROR';
    }
  }

  static String _errorTypeReadable(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badCertificate:
        return 'Bad SSL certificate';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.badResponse:
        return 'Server returned an error';
      default:
        return 'Unknown error (${type.name})';
    }
  }
}
