import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging_service/logging_service.dart';

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
    test('request → response eyni modelə yazılır', () {
      final storage = DebugStorage();
      final options = _options();

      storage.addRequest(options);
      expect(storage.count, 1);
      expect(storage.requests.first.isPending, isTrue);

      storage.addResponse(
        Response<dynamic>(requestOptions: options, statusCode: 200),
      );

      expect(storage.count, 1, reason: 'dublikat sətir yaranmamalıdır');
      expect(storage.requests.first.isSuccess, isTrue);
      expect(storage.requests.first.elapsedTime, isNotNull);
    });

    test('clear() sonrası id-lər təkrarlanmır', () {
      final storage = DebugStorage();
      storage.addRequest(_options());
      final firstId = storage.requests.first.id;

      storage.clear();
      storage.addRequest(_options(path: '/api/other'));

      expect(storage.requests.first.id, isNot(firstId));
    });

    test('deleteById siyahı sürüşəndə də düzgün elementi silir', () {
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

    test('maxRequests limiti tətbiq olunur', () {
      final storage = DebugStorage()..configure(maxRequests: 3);
      for (var i = 0; i < 10; i++) {
        storage.addRequest(_options(path: '/p$i'));
      }
      expect(storage.count, 3);
      storage.configure(maxRequests: 200);
    });

    test('recording dayandırılanda log yığılmır', () {
      final storage = DebugStorage()..setRecording(false);
      storage.addRequest(_options());
      expect(storage.count, 0);
      storage.setRecording(true);
    });
  });

  group('DebugModel', () {
    test('4xx cavab error sayılır, pending isə yox', () {
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

    test('backend error body-dən mesaj çıxarılır', () {
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
            data: {'detail': 'Xəstə tapılmadı'},
          ),
        ),
      );

      expect(model.errorStatusCode, '400');
      expect(model.errorStatusMessage, 'Xəstə tapılmadı');
    });

    test('string JSON error body də parse olunur', () {
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

    test('axtarış metod və url üzrə işləyir', () {
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
    test('int header dəyəri sətrə çevrilir', () {
      final headers = LogFormatter.normalizeHeaders({
        'content-length': 120,
        'accept': ['a', 'b'],
      });
      expect(headers['content-length'], '120');
      expect(headers['accept'], 'a, b');
    });

    test('həssas header maskalanır', () {
      final headers = LogFormatter.normalizeHeaders(
        {'Authorization': 'Bearer abcdefghijklmnop'},
        redact: true,
      );
      expect(headers['Authorization'], isNot(contains('abcdefghijklmnop')));
    });

    test('kodlana bilməyən obyekt exception atmır', () {
      expect(LogFormatter.encode(Object()), isA<String>());
      expect(LogFormatter.pretty(DateTime(2026)), isA<String>());
    });

    test('FormData map-ə çevrilir', () {
      final formData = FormData.fromMap({'name': 'Samir'});
      final map = LogFormatter.formDataToMap(formData);
      expect((map['fields'] as Map)['name'], 'Samir');
    });
  });

  group('CopyHelper', () {
    test('cURL-də tək dırnaq escape olunur', () {
      final model = DebugModel(
        id: 1,
        requestOptions: _options(method: 'POST', data: {"note": "it's ok"}),
        requestStartTime: DateTime.now(),
      );
      final curl = CopyHelper.generateCurlCommand(model);
      expect(curl, contains(r"'\''"));
      expect(curl, contains('curl -X POST'));
    });

    test('FormData body -F ilə yazılır', () {
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
}
