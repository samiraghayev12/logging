import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns 200 for every request and remembers the URLs that were called.
class _RecordingAdapter implements HttpClientAdapter {
  final urls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add(options.uri.toString());
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _api = [
  DebugEnvironment(
    'Dev',
    baseUrl: 'https://dev.api.example.com',
    color: Colors.green,
  ),
  DebugEnvironment('Prod', baseUrl: 'https://api.example.com/'),
];

(Dio, _RecordingAdapter) _dio(String baseUrl, List<DebugEnvironment> envs) {
  final adapter = _RecordingAdapter();
  final dio = Dio(BaseOptions(baseUrl: baseUrl))
    ..httpClientAdapter = adapter
    ..addDebugLogger(environments: envs, printToConsole: false);
  return (dio, adapter);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DebugEnvironments.instance.reset();
    DebugStorage()
      ..setRecording(true)
      ..clear();
  });

  test('default: the app\'s base URL is used', () async {
    final (dio, adapter) = _dio('https://api.example.com', _api);
    await dio.get<dynamic>('/users');
    expect(DioDebugLogger.environment, isNull);
    expect(adapter.urls.single, 'https://api.example.com/users');
  });

  test(
    'switching rewrites the base URL and the log shows the real URL',
    () async {
      final (dio, adapter) = _dio('https://api.example.com', _api);
      await DioDebugLogger.setEnvironment('Dev');
      await dio.get<dynamic>('/users', queryParameters: {'page': 2});

      expect(adapter.urls.single, 'https://dev.api.example.com/users?page=2');
      expect(
        DebugStorage().requests.single.url,
        'https://dev.api.example.com/users?page=2',
      );

      await DioDebugLogger.setEnvironment(null);
      await dio.get<dynamic>('/users');
      expect(adapter.urls.last, 'https://api.example.com/users');
    },
  );

  test('requests to other hosts are never changed', () async {
    final (dio, adapter) = _dio('https://api.example.com', _api);
    await DioDebugLogger.setEnvironment('Dev');
    await dio.get<dynamic>('https://cdn.example.com/logo.png');
    await dio.get<dynamic>('/x');
    expect(adapter.urls.first, 'https://cdn.example.com/logo.png');
    expect(adapter.urls.last, 'https://dev.api.example.com/x');
  });

  test('several Dio instances switch together by name', () async {
    final (api, apiAdapter) = _dio('https://api.example.com', _api);
    final (auth, authAdapter) = _dio('https://auth.example.com', const [
      DebugEnvironment('Dev', baseUrl: 'https://dev.auth.example.com'),
      DebugEnvironment('Prod', baseUrl: 'https://auth.example.com'),
    ]);
    expect(DioDebugLogger.environments.names, ['Dev', 'Prod']);

    await DioDebugLogger.setEnvironment('Dev');
    await api.get<dynamic>('/me');
    await auth.post<dynamic>('/token');
    expect(apiAdapter.urls.single, 'https://dev.api.example.com/me');
    expect(authAdapter.urls.single, 'https://dev.auth.example.com/token');
  });

  test('a Dio without the selected environment is left alone', () async {
    final (api, _) = _dio('https://api.example.com', _api);
    final (other, otherAdapter) = _dio('https://pay.example.com', const [
      DebugEnvironment('Prod', baseUrl: 'https://pay.example.com'),
    ]);
    await DioDebugLogger.setEnvironment('Dev');
    await api.get<dynamic>('/a');
    await other.get<dynamic>('/b');
    expect(otherAdapter.urls.single, 'https://pay.example.com/b');
  });

  test('the choice is saved and restored on the next start', () async {
    String? changed;
    _dio('https://api.example.com', _api);
    DioDebugLogger.onEnvironmentChanged = (name) => changed = name;
    await DioDebugLogger.setEnvironment('Dev');
    expect(changed, 'Dev');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DebugEnvironments.storageKey), 'Dev');

    // Simulate an app restart: registry is empty, storage keeps the choice.
    DebugEnvironments.instance.reset();
    final (dio, adapter) = _dio('https://api.example.com', _api);
    await dio.get<dynamic>('/users');
    expect(DioDebugLogger.environment, 'Dev');
    expect(adapter.urls.single, 'https://dev.api.example.com/users');
  });

  test(
    'a saved environment that no longer exists falls back to default',
    () async {
      SharedPreferences.setMockInitialValues({
        DebugEnvironments.storageKey: 'Old',
      });
      final (dio, adapter) = _dio('https://api.example.com', _api);
      await dio.get<dynamic>('/users');
      expect(DioDebugLogger.environment, isNull);
      expect(adapter.urls.single, 'https://api.example.com/users');
    },
  );

  test(
    'setEnvironments: available before any Dio, used by Dio without its own list',
    () async {
      DioDebugLogger.setEnvironments(_api);
      expect(DioDebugLogger.environments.names, ['Dev', 'Prod']);
      await DioDebugLogger.setEnvironment('Dev');

      // Created later, without its own environments (e.g. a lazy singleton).
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = adapter
        ..addDebugLogger(printToConsole: false);
      await dio.get<dynamic>('/users');
      expect(adapter.urls.single, 'https://dev.api.example.com/users');
    },
  );

  test('setEnvironments(enabled: false) does nothing', () {
    DioDebugLogger.setEnvironments(_api, enabled: false);
    expect(DioDebugLogger.environments.isEmpty, isTrue);
  });

  test('unknown names throw', () async {
    _dio('https://api.example.com', _api);
    expect(() => DioDebugLogger.setEnvironment('Nope'), throwsArgumentError);
  });

  test('release builds (enabled: false) register nothing', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = adapter
      ..addDebugLogger(enabled: false, environments: _api);
    expect(dio.interceptors.whereType<DebugLogging>(), isEmpty);
    expect(DioDebugLogger.environments.isEmpty, isTrue);
    await dio.get<dynamic>('/users');
    expect(adapter.urls.single, 'https://api.example.com/users');
  });

  testWidgets('switch from the log page; the button shows the badge', (
    tester,
  ) async {
    await tester.runAsync(() async {
      _dio('https://api.example.com', _api);
      await DioDebugLogger.environments.ready;
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: DioDebugLogger.builder(),
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('DEV'), findsNothing);

    await tester.tap(find.byIcon(Icons.bug_report_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Default environment'), findsOneWidget);

    await tester.tap(find.text('Default environment'));
    await tester.pumpAndSettle();
    expect(find.text('Environment'), findsOneWidget);
    expect(find.text('https://dev.api.example.com'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Dev'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(DioDebugLogger.environment, 'Dev');
    expect(find.textContaining('Switched to Dev'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('DEV'), findsOneWidget);
  });
}
