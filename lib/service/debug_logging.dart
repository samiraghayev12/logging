import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../environment/debug_environment.dart';
import '../storage/debug_storage.dart';
import '../utils/log_formatter.dart';
import '../utils/redaction.dart';
import 'release_guard.dart';

/// Dio interceptor that records every request in `DebugStorage` and prints
/// it to the console in debug mode.
///
/// Usually added with `dio.addDebugLogger()`; adding it directly also works:
/// ```dart
/// dio.interceptors.add(DebugLogging());
/// ```
///
/// Disabled in release builds unless [enabled] is set: a disabled
/// interceptor passes requests through without recording or changing them.
class DebugLogging extends Interceptor {
  DebugLogging({
    this.enabled = kDebugMode,
    this.printToConsole = kDebugMode,
    this.redactSensitiveHeaders = true,
    this.maxConsoleBodyLength = 2000,
    this.environments = const [],
    this.client,
  }) {
    if (!enabled) return;
    ReleaseGuard.check('DebugLogging');
    DebugEnvironments.instance.register(environments);
  }

  /// Whether requests are recorded. Defaults to `false` in release builds.
  final bool enabled;

  /// Whether to print to the console.
  final bool printToConsole;

  /// Whether secrets (passwords, tokens, keys…) are masked in the console,
  /// in headers, bodies and URLs.
  final bool redactSensitiveHeaders;

  /// Maximum body length printed to the console.
  final int maxConsoleBodyLength;

  /// Backends this Dio can be switched to from the log page. When empty, the
  /// list from `DioDebugLogger.setEnvironments` is used.
  final List<DebugEnvironment> environments;

  /// The Dio this interceptor belongs to. "Retry" resends with it, so
  /// certificate pinning and other settings are kept.
  final Dio? client;

  /// Key under which [client] is stored in `RequestOptions.extra`.
  static const clientKey = 'dio_debug_logger.client';

  final DebugStorage debug = DebugStorage();

  Object? _safe(Object? data) =>
      redactSensitiveHeaders ? Redaction.redact(data) : data;

  String _safeUrl(Uri uri) =>
      redactSensitiveHeaders ? Redaction.url(uri.toString()) : uri.toString();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!enabled) return handler.next(options);

    final registry = DebugEnvironments.instance;
    final group = environments.isNotEmpty ? environments : registry.global;
    if (group.isNotEmpty) {
      await registry.ready;
      final baseUrl = registry.resolve(group, options.baseUrl);
      if (baseUrl != null) options.baseUrl = baseUrl;
    }

    if (client != null) options.extra[clientKey] = client;
    _guard(() => debug.addRequest(options), 'addRequest');

    if (printToConsole) {
      debugPrint('🐙 REQUEST [${options.method}] ${_safeUrl(options.uri)}');
      if (options.headers.isNotEmpty) {
        debugPrint(
          '   HEADERS: ${LogFormatter.normalizeHeaders(options.headers, redact: redactSensitiveHeaders)}',
        );
      }
      if (options.data != null) {
        debugPrint(
          '   BODY: ${_truncate(LogFormatter.encode(_safe(options.data)))}',
        );
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!enabled) return handler.next(response);
    _guard(() => debug.addResponse(response), 'addResponse');

    if (printToConsole) {
      debugPrint(
        '🦑 RESPONSE [${response.statusCode}] ${_safeUrl(response.requestOptions.uri)}',
      );
      debugPrint(
        '   DATA: ${_truncate(LogFormatter.encode(_safe(response.data)))}',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);
    _guard(() => debug.addError(err), 'addError');

    if (printToConsole) {
      debugPrint(
        '🦀 ERROR [${err.response?.statusCode ?? err.type.name}] ${_safeUrl(err.requestOptions.uri)}',
      );
      debugPrint('   TYPE: ${err.type}');
      if (err.message != null) debugPrint('   MESSAGE: ${err.message}');
      if (err.response?.data != null) {
        debugPrint(
          '   RESPONSE DATA: ${_truncate(LogFormatter.encode(_safe(err.response?.data)))}',
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
