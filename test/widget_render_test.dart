import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging_service/logging_service.dart';

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

  // Hələ cavabı gəlməmiş sorğu.
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

  testWidgets('böyük sistem font ölçüsündə də daşma olmur', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const DebugPage(), textScale: 2.0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detal səhifəsi request/response tablarını göstərir',
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

  testWidgets('analitika səhifəsi render olunur', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const DebugStats()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Analytics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DebugOverlay FAB-ı göstərir və enabled=false-da gizlədir',
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

  testWidgets('siyahı status filtri ilə süzülür', (tester) async {
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
      'MaterialApp.builder içindəki FAB heç bir əlavə konfiqurasiya olmadan '
      'log səhifəsini açır', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // Qəsdən: navigatorObservers YOXDUR, navigatorKey YOXDUR.
        builder: NetworkLogger.overlayBuilder(),
        home: const Scaffold(body: Center(child: Text('app'))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.bug_report_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Network Logs'), findsOneWidget);
    expect(NetworkLogger.isOpen, isTrue);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(NetworkLogger.isOpen, isFalse);
  });
}
