import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';

RequestOptions _options({
  String method = 'GET',
  String path = '/api/patients',
  String baseUrl = 'https://example.com',
  dynamic data,
}) =>
    RequestOptions(path: path, baseUrl: baseUrl, method: method, data: data);

void main() {
  setUp(() {
    DebugStorage()
      ..setRecording(true)
      ..clear();
  });

  group('DebugStorage', () {
    test('request → response is written to the same model', () {
      final storage = DebugStorage();
      final options = _options();

      storage.addRequest(options);
      expect(storage.count, 1);
      expect(storage.requests.first.isPending, isTrue);

      storage.addResponse(
        Response<dynamic>(requestOptions: options, statusCode: 200),
      );

      expect(storage.count, 1, reason: 'no duplicate row should be created');
      expect(storage.requests.first.isSuccess, isTrue);
      expect(storage.requests.first.elapsedTime, isNotNull);
    });

    test('ids are not reused after clear()', () {
      final storage = DebugStorage();
      storage.addRequest(_options());
      final firstId = storage.requests.first.id;

      storage.clear();
      storage.addRequest(_options(path: '/api/other'));

      expect(storage.requests.first.id, isNot(firstId));
    });

    test('deleteById removes the right item when the list shifts', () {
      final storage = DebugStorage();
      storage
        ..addRequest(_options(path: '/a'))
        ..addRequest(_options(path: '/b'))
        ..addRequest(_options(path: '/c'));

      final target = storage.requests[1];
      storage.deleteById(target.id);

      expect(storage.count, 2);
      expect(storage.requests.any((r) => r.id == target.id), isFalse);
    });

    test('maxRequests limit is applied', () {
      final storage = DebugStorage()..configure(maxRequests: 3);
      for (var i = 0; i < 10; i++) {
        storage.addRequest(_options(path: '/p$i'));
      }
      expect(storage.count, 3);
      storage.configure(maxRequests: 200);
    });

    test('nothing is logged while recording is paused', () {
      final storage = DebugStorage()..setRecording(false);
      storage.addRequest(_options());
      expect(storage.count, 0);
      storage.setRecording(true);
    });
  });

  group('DebugModel', () {
    test('4xx response counts as error, pending does not', () {
      final options = _options();
      final pending = DebugModel(
        id: 1,
        requestOptions: options,
        requestStartTime: DateTime.now(),
      );
      expect(pending.hasError, isFalse);
      expect(pending.isPending, isTrue);
      expect(pending.statusCode, 'Pending');
      expect(pending.elapsedTimeInMs, '—');

      pending
        ..response = Response<dynamic>(requestOptions: options, statusCode: 404)
        ..requestEndTime = DateTime.now();
      expect(pending.hasError, isTrue);
      expect(pending.status, DebugStatus.clientError);
    });

    test('message is extracted from the backend error body', () {
      final options = _options();
      final model = DebugModel(
        id: 1,
        requestOptions: options,
        requestStartTime: DateTime.now(),
        requestEndTime: DateTime.now(),
        dioError: DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 400,
            data: {'detail': 'Patient not found'},
          ),
        ),
      );

      expect(model.errorStatusCode, '400');
      expect(model.errorStatusMessage, 'Patient not found');
    });

    test('string JSON error body is parsed too', () {
      final options = _options();
      final model = DebugModel(
        id: 1,
        requestOptions: options,
        requestStartTime: DateTime.now(),
        requestEndTime: DateTime.now(),
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 500,
          data: '{"message":"Server error"}',
        ),
      );
      expect(model.errorStatusMessage, 'Server error');
    });

    test('search matches method and url', () {
      final model = DebugModel(
        id: 1,
        requestOptions: _options(method: 'POST', path: '/api/appointments'),
        requestStartTime: DateTime.now(),
      );
      expect(model.matches('post'), isTrue);
      expect(model.matches('APPOINT'), isTrue);
      expect(model.matches('zzz'), isFalse);
      expect(model.matches(''), isTrue);
    });
  });

  group('LogFormatter', () {
    test('int header value is converted to string', () {
      final headers = LogFormatter.normalizeHeaders({
        'content-length': 120,
        'accept': ['a', 'b'],
      });
      expect(headers['content-length'], '120');
      expect(headers['accept'], 'a, b');
    });

    test('sensitive header is masked', () {
      final headers = LogFormatter.normalizeHeaders(
        {'Authorization': 'Bearer abcdefghijklmnop'},
        redact: true,
      );
      expect(headers['Authorization'], isNot(contains('abcdefghijklmnop')));
    });

    test('unencodable object does not throw', () {
      expect(LogFormatter.encode(Object()), isA<String>());
      expect(LogFormatter.pretty(DateTime(2026)), isA<String>());
    });

    test('FormData is converted to a map', () {
      final formData = FormData.fromMap({'name': 'Samir'});
      final map = LogFormatter.formDataToMap(formData);
      expect((map['fields'] as Map)['name'], 'Samir');
    });
  });

  group('CopyHelper', () {
    test('single quotes are escaped in cURL', () {
      final model = DebugModel(
        id: 1,
        requestOptions: _options(method: 'POST', data: {"note": "it's ok"}),
        requestStartTime: DateTime.now(),
      );
      final curl = CopyHelper.generateCurlCommand(model);
      expect(curl, contains(r"'\''"));
      expect(curl, contains('curl -X POST'));
    });

    test('FormData body is written with -F', () {
      final model = DebugModel(
        id: 1,
        requestOptions: _options(
          method: 'POST',
          data: FormData.fromMap({'name': 'Samir'}),
        ),
        requestStartTime: DateTime.now(),
      );
      expect(CopyHelper.generateCurlCommand(model), contains('-F'));
    });
  });

  group('Setup API', () {
    test('addDebugLogger adds the interceptor only once', () {
      final dio = Dio()
        ..addDebugLogger()
        ..addDebugLogger();
      expect(dio.interceptors.whereType<DebugLogging>().length, 1);
    });

    test('addDebugLogger(enabled: false) adds nothing', () {
      final dio = Dio()..addDebugLogger(enabled: false);
      expect(dio.interceptors.whereType<DebugLogging>(), isEmpty);
    });

    test('deprecated NetworkLogger forwards to DioDebugLogger', () {
      final custom = Dio();
      // ignore: deprecated_member_use_from_same_package
      NetworkLogger.retryClientBuilder = () => custom;
      addTearDown(() => DioDebugLogger.retryClientBuilder = null);
      expect(DioDebugLogger.createRetryClient(), same(custom));
    });
  });
}
