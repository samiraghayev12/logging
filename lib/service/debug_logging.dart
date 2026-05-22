import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging_service/storage/debug_storage.dart';

class DebugLogging extends Interceptor {
  final debug = DebugStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🐙 REQUEST [${options.method}] ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   QUERY: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('   BODY: ${options.data}');
      }
    }

    try {
      debug.addRequest(options);
    } catch (e) {
      if (kDebugMode) debugPrint('DebugLogging.addRequest failed: $e');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '🦑 RESPONSE [${response.statusCode}] ${response.requestOptions.uri}');
      debugPrint('   DATA: ${response.data}');
    }

    try {
      debug.addResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('DebugLogging.addResponse failed: $e');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '🦀 ERROR [${err.response?.statusCode ?? err.type.name}] ${err.requestOptions.uri}');
      debugPrint('   TYPE: ${err.type}');
      if (err.message != null) {
        debugPrint('   MESSAGE: ${err.message}');
      }
      if (err.response?.data != null) {
        debugPrint('   RESPONSE DATA: ${err.response?.data}');
      }
      if (err.error != null) {
        debugPrint('   UNDERLYING: ${err.error}');
      }
    }

    try {
      debug.addError(err);
    } catch (e) {
      if (kDebugMode) debugPrint('DebugLogging.addError failed: $e');
    }

    handler.next(err);
  }
}
