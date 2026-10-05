import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';
import 'package:dio_debug_logger/utils/redaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _mask = Redaction.mask;

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      'set-cookie': ['session=abc; HttpOnly'],
    },
  );

  @override
  void close({bool force = false}) {}
}

const _secrets = [
  'hunter2',
  'eyJ.secret.jwt',
  'rt_999',
  'sk_live_1',
  '4111111111111111',
];

void _expectNoSecrets(String text) {
  for (final secret in _secrets) {
    expect(text, isNot(contains(secret)), reason: 'leaked "$secret"');
  }
}

Future<DebugModel> _loginRequest({Dio? into}) async {
  DebugStorage().clear();
  final dio =
      into ??
      (Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _Adapter({
          'access_token': 'eyJ.secret.jwt',
          'refresh_token': 'rt_999',
          'user': {'name': 'Aysel', 'email': 'a@example.com'},
        })
        ..addDebugLogger(printToConsole: false));
  await dio.post<dynamic>(
    '/login',
    queryParameters: {'api_key': 'sk_live_1', 'lang': 'az'},
    data: {
      'email': 'a@example.com',
      'password': 'hunter2',
      'card': {'cardNumber': '4111111111111111', 'holder': 'AYSEL'},
    },
    options: Options(headers: {'Authorization': 'Bearer eyJ.secret.jwt'}),
  );
  return DebugStorage().requests.first;
}

void main() {
  setUp(() {
    Redaction.reveal.value = false;
    Redaction.extraKeys.clear();
    DioDebugLogger.retryClientBuilder = null;
  });

  group('isSensitive', () {
    test('matches common secret names in any style', () {
      for (final key in [
        'password',
        'user_password',
        'Passwd',
        'accessToken',
        'refresh-token',
        'id_token',
        'X-Api-Key',
        'apiKey',
        'client_secret',
        'Authorization',
        'Cookie',
        'Set-Cookie',
        'pin',
        'OTP',
        'cvv',
        'card_number',
        'sessionId',
        'private_key',
        'credentials',
        'signature',
      ]) {
        expect(Redaction.isSensitive(key), isTrue, reason: key);
      }
    });

    test('leaves normal fields alone', () {
      for (final key in [
        'name',
        'email',
        'id',
        'author',
        'shipping',
        'pinned',
        'spinner',
        'description',
        'status',
        'page',
        'lang',
        'patientId',
      ]) {
        expect(Redaction.isSensitive(key), isFalse, reason: key);
      }
    });

    test('extra keys can be added', () {
      expect(Redaction.isSensitive('national_id'), isFalse);
      DioDebugLogger.sensitiveKeys.add('nationalId');
      expect(Redaction.isSensitive('national_id'), isTrue);
    });
  });

  group('redact', () {
    test('nested maps and lists', () {
      final result = Redaction.redact({
        'user': {'name': 'A', 'password': 'hunter2'},
        'tokens': [
          {'access_token': 'x', 'scope': 'read'},
        ],
        'otp': null,
        'pin': 1234,
      });
      expect(result, {
        'user': {'name': 'A', 'password': _mask},
        'tokens': _mask,
        'otp': null,
        'pin': _mask,
      });
    });

    test('JSON strings stay strings', () {
      final result = Redaction.redact('{"password":"hunter2","a":1}') as String;
      expect(jsonDecode(result), {'password': _mask, 'a': 1});
    });

    test('form-encoded strings', () {
      expect(
        Redaction.redact('username=aysel&password=hunter2&remember=1'),
        'username=aysel&password=$_mask&remember=1',
      );
    });

    test('FormData', () {
      final form = FormData.fromMap({'name': 'A', 'pin': '1234'});
      expect(Redaction.redact(form), {'name': 'A', 'pin': _mask});
    });

    test('plain text and numbers are unchanged', () {
      expect(Redaction.redact('hello'), 'hello');
      expect(Redaction.redact(42), 42);
    });

    test('URL query parameters, fragment kept', () {
      expect(
        Redaction.url('https://x.com/a?token=abc&page=2#top'),
        'https://x.com/a?token=$_mask&page=2#top',
      );
      expect(Redaction.url('https://x.com/a'), 'https://x.com/a');
    });

    test('the original data is never modified', () {
      final data = {'password': 'hunter2'};
      Redaction.redact(data);
      expect(data['password'], 'hunter2');
    });
  });

  group('nothing leaks by default', () {
    test('copy formats and export', () async {
      final model = await _loginRequest();
      _expectNoSecrets(CopyHelper.generateCurlCommand(model, redact: true));
      _expectNoSecrets(CopyHelper.generatePostmanJson(model, redact: true));
      _expectNoSecrets(CopyHelper.generateJsonRequest(model, redact: true));
      _expectNoSecrets(CopyHelper.generateSummary(model));
      _expectNoSecrets(CopyHelper.generateResponseBody(model));
      _expectNoSecrets(jsonEncode(DebugStorage().exportAll()));

      expect(
        CopyHelper.generateCurlCommand(model, redact: true),
        contains('a@example.com'),
      );
      expect(CopyHelper.generateCurlCommand(model), contains('hunter2'));
    });

    test('console output', () async {
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => lines.add('$message');
      addTearDown(() => debugPrint = original);

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _Adapter({
          'access_token': 'eyJ.secret.jwt',
          'refresh_token': 'rt_999',
        })
        ..addDebugLogger(printToConsole: true);
      await _loginRequest(into: dio);

      expect(lines, isNotEmpty);
      _expectNoSecrets(lines.join('\n'));
    });

    testWidgets('detail page hides secrets until the eye is tapped', (
      tester,
    ) async {
      late DebugModel model;
      await tester.runAsync(() async => model = await _loginRequest());
      await tester.pumpWidget(
        MaterialApp(home: DebugDetail(debugModel: model)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('hunter2'), findsNothing);
      expect(find.textContaining('sk_live_1'), findsNothing);
      expect(find.textContaining('eyJ.secret.jwt'), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pumpAndSettle();
      expect(Redaction.reveal.value, isTrue);
      expect(find.textContaining('sk_live_1'), findsWidgets);
    });
  });

  group('release safety', () {
    test('a disabled interceptor records and changes nothing', () async {
      DebugStorage().clear();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _Adapter({})
        ..interceptors.add(DebugLogging(enabled: false));
      await dio.get<dynamic>('/x');
      expect(DebugStorage().count, 0);
    });

    test(
      'DebugLogging, DebugOverlay and the deprecated API are off in release by default',
      () {
        expect(DebugLogging().enabled, kDebugMode);
        expect(const DebugOverlay(child: SizedBox()).enabled, kDebugMode);
      },
    );
  });

  group('retry', () {
    test('uses the Dio that sent the request, or retryClientBuilder', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _Adapter({})
        ..addDebugLogger(printToConsole: false);
      final model = await _loginRequest(into: dio);
      expect(DioDebugLogger.createRetryClient(model), same(dio));

      final custom = Dio();
      DioDebugLogger.retryClientBuilder = () => custom;
      expect(DioDebugLogger.createRetryClient(model), same(custom));
    });
  });
}
