import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging_service/storage/debug_storage.dart';

class DebugLogging extends Interceptor {
  final debug = DebugStorage();
  final Stopwatch stopwatch = Stopwatch();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    stopwatch.start();
    if (kDebugMode) {
      print('🐙 REQUEST [ ${options.method}] => URL: ${options.uri} => BODY: ${options.data} => TIME: ${DateTime.now()}');
    }
    debug.addRequest(options);
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    stopwatch.stop();
    final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    if (kDebugMode) {
      print('🦑 RESPONSE [ ${response.statusCode}] => DATA: ${response.data} ] => TIME: ${DateTime.now()} => ELAPSED TIME: $elapsedMilliseconds ms');
    }
    debug.addResponse(response);
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    stopwatch.stop();
    final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    if (kDebugMode) {
      print(
          '🦀 ERROR [ ${err.response?.statusCode}] => PATH: ${err.requestOptions.path} ] => TIME: ${DateTime.now()} => ELAPSED TIME: $elapsedMilliseconds ms');
    }
    debug.addError(err);
    return super.onError(err, handler);
  }
}
