import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';

void _seed() {
  final storage = DebugStorage()
    ..setRecording(true)
    ..clear();

  final ok = RequestOptions(
    path: '/api/v1/patients/very/long/path/segment/that/keeps/going/forever',
    baseUrl: 'https://very-long-subdomain.hospital-management-system.example.com',
    method: 'GET',
  );
  storage.addRequest(ok);
  storage.addResponse(
    Response<dynamic>(
      requestOptions: ok,
      statusCode: 200,
      data: {'items': List.generate(5, (i) => {'id': i, 'name': 'Patient $i'})},
      headers: Headers.fromMap({
        'content-type': ['application/json'],
        'x-very-long-header-name-for-overflow-testing': [
          'a-really-long-header-value-' * 4,
        ],
      }),
    ),
  );

  final failed = RequestOptions(
    path: '/api/v1/appointments',
    baseUrl: 'https://example.com',
    method: 'POST',
    data: {'note': "it's a long note " * 10},
  );
  storage.addRequest(failed);
  storage.addError(
    DioException(
      requestOptions: failed,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: failed,
        statusCode: 422,
        data: {'detail': 'Validation failed for a very long reason ' * 5},
      ),
    ),
  );

  // A request with no response yet.
  storage.addRequest(
    RequestOptions(path: '/api/v1/pending', baseUrl: 'https://example.com'),
  );
}

Widget _host(Widget child, {double textScale = 1.0}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    );

void main() {
  setUp(_seed);

  final sizes = <String, Size>{
    'small phone': Size(320, 640),
    'phone': Size(390, 844),
    'tablet': Size(834, 1112),
  };

  for (final entry in sizes.entries) {
    testWidgets('DebugPage overflow-suz render olunur — ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const DebugPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Network Logs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('no overflow with a large system font size', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const DebugPage(), textScale: 2.0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail page shows request/response tabs',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final model = DebugStorage().requests.firstWhere((r) => r.hasError);
    await tester.pumpWidget(_host(DebugDetail(debugModel: model)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Request Details'), findsOneWidget);
    expect(find.text('Error'), findsWidgets);

    await tester.tap(find.text('Error').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('analytics page renders', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const DebugStats()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Analytics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DebugOverlay shows the button and hides it when enabled=false',
      (tester) async {
    await tester.pumpWidget(
      _host(const DebugOverlay(child: Scaffold(body: Text('app')))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.bug_report_rounded), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const DebugOverlay(
          enabled: false,
          child: Scaffold(body: Text('app')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.bug_report_rounded), findsNothing);
  });

  _overlayOnlyIntegration();

  testWidgets('DioDebugLogger.builder wraps an existing builder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: DioDebugLogger.builder(
          builder: (context, child) => KeyedSubtree(
            key: const ValueKey('inner-builder'),
            child: child!,
          ),
        ),
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('app'), findsOneWidget);
    expect(find.byKey(const ValueKey('inner-builder')), findsOneWidget);
    expect(find.byIcon(Icons.bug_report_rounded), findsOneWidget);
  });

  testWidgets('DioDebugLogger.builder(enabled: false) shows no button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: DioDebugLogger.builder(enabled: false),
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('app'), findsOneWidget);
    expect(find.byIcon(Icons.bug_report_rounded), findsNothing);
  });

  testWidgets('list is filtered by status', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const DebugPage()));
    await tester.pump(const Duration(milliseconds: 300));

    final errorChip = find.text('Errors (1)');
    expect(errorChip, findsOneWidget);
    await tester.ensureVisible(errorChip);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(errorChip);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('422'), findsOneWidget);
    expect(find.text('200'), findsNothing);
  });
}

void _overlayOnlyIntegration() {
  testWidgets(
      'button in MaterialApp.builder opens the log page without extra setup',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // Intentionally no navigatorObservers and no navigatorKey.
        builder: DioDebugLogger.builder(),
        home: const Scaffold(body: Center(child: Text('app'))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.bug_report_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Network Logs'), findsOneWidget);
    expect(DioDebugLogger.isOpen, isTrue);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(DioDebugLogger.isOpen, isFalse);
  });
}
