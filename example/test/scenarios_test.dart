import 'package:dio/dio.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';
import 'package:dio_debug_logger_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every demo scenario produces the expected result', () async {
    DebugStorage().clear();
    final api = Api();
    final results = <String, Object>{};

    for (final (_, scenarios) in scenarioGroups) {
      for (final scenario in scenarios) {
        try {
          final res = await scenario.run(api);
          results[scenario.title] = res.statusCode!;
        } on DioException catch (e) {
          results[scenario.title] = e.response?.statusCode ?? e.type;
        }
      }
    }

    expect(results, {
      'Login → access token': 200,
      'Wrong password → 401': 401,
      'Profile (Bearer token)': 200,
      'Expired token → 401': 401,
      'Refresh token': 200,
      'List users (query params)': 200,
      'Get one user': 200,
      'Create user → 201': 201,
      'Replace user': 200,
      'Update one field': 200,
      'Delete user → 204': 204,
      'Search with filters': 200,
      'Large response (100 items)': 200,
      'Multipart upload (FormData)': 201,
      'Slow request (3 s, pending)': 200,
      '400 Validation errors': 400,
      '403 Forbidden': 403,
      '404 Not found': 404,
      '409 Conflict': 409,
      '422 Problem+JSON': 422,
      '429 Too many requests': 429,
      '500 Server error': 500,
      '503 Plain-text error': 503,
      'Connection timeout': DioExceptionType.connectionTimeout,
      'No internet (DNS error)': DioExceptionType.connectionError,
      'Cancelled by user': DioExceptionType.cancel,
    });

    final storage = DebugStorage();
    expect(storage.count, results.length);
    expect(storage.pendingCount, 0);
    final validation = storage.requests.firstWhere((r) => r.url.contains('/orders'));
    expect(validation.errorStatusMessage, 'Validation failed');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
