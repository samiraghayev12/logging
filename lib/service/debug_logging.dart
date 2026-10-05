import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../environment/debug_environment.dart';
import '../storage/debug_storage.dart';
import '../utils/log_formatter.dart';

/// Dio interceptor that records every request in `DebugStorage` and prints
/// it to the console in debug mode.
///
/// Usually added with `dio.addDebugLogger()`; adding it directly also works:
/// ```dart
/// dio.interceptors.add(DebugLogging());
/// ```
class DebugLogging extends Interceptor {
  DebugLogging({
    this.printToConsole = kDebugMode,
    this.redactSensitiveHeaders = true,
    this.maxConsoleBodyLength = 2000,
    this.environments = const [],
  }) {
    DebugEnvironments.instance.register(environments);
  }

  /// Whether to print to the console.
  final bool printToConsole;

  /// Whether `Authorization` and similar headers are masked in the console.
  final bool redactSensitiveHeaders;

  /// Maximum body length printed to the console.
  final int maxConsoleBodyLength;

  /// Backends this Dio can be switched to from the log page. When empty, the
  /// list from `DioDebugLogger.setEnvironments` is used.
  final List<DebugEnvironment> environments;

  final DebugStorage debug = DebugStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final registry = DebugEnvironments.instance;
    final group = environments.isNotEmpty ? environments : registry.global;
    if (group.isNotEmpty) {
      await registry.ready;
      final baseUrl = registry.resolve(group, options.baseUrl);
      if (baseUrl != null) options.baseUrl = baseUrl;
    }

    _guard(() => debug.addRequest(options), 'addRequest');

    if (printToConsole) {
      debugPrint('🐙 REQUEST [${options.method}] ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   QUERY: ${options.queryParameters}');
      }
      if (options.headers.isNotEmpty) {
        debugPrint(
          '   HEADERS: ${LogFormatter.normalizeHeaders(options.headers, redact: redactSensitiveHeaders)}',
        );
      }
      if (options.data != null) {
        debugPrint('   BODY: ${_truncate(LogFormatter.encode(options.data))}');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _guard(() => debug.addResponse(response), 'addResponse');

    if (printToConsole) {
      debugPrint(
        '🦑 RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
      );
      debugPrint('   DATA: ${_truncate(LogFormatter.encode(response.data))}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _guard(() => debug.addError(err), 'addError');

    if (printToConsole) {
      debugPrint(
        '🦀 ERROR [${err.response?.statusCode ?? err.type.name}] ${err.requestOptions.uri}',
      );
      debugPrint('   TYPE: ${err.type}');
      if (err.message != null) debugPrint('   MESSAGE: ${err.message}');
      if (err.response?.data != null) {
        debugPrint(
          '   RESPONSE DATA: ${_truncate(LogFormatter.encode(err.response?.data))}',
        );
      }
      if (err.error != null) debugPrint('   UNDERLYING: ${err.error}');
    }

    handler.next(err);
  }

  String _truncate(String value) {
    if (value.length <= maxConsoleBodyLength) return value;
    return '${value.substring(0, maxConsoleBodyLength)}… (${value.length} chars)';
  }

  void _guard(VoidCallback action, String label) {
    try {
      action();
    } catch (e) {
      if (kDebugMode) debugPrint('DebugLogging.$label failed: $e');
    }
  }
}
