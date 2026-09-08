@Tags(['golden'])
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging_service/logging_service.dart';

void _seed() {
  final storage = DebugStorage()
    ..setRecording(true)
    ..clear();

  final ok = RequestOptions(
    path: '/api/v1/patients/00000000-1111-2222-3333-444444444444/appointments',
    baseUrl: 'https://hospital-management-system.example.com',
    method: 'GET',
  );
  storage.addRequest(ok);
  storage.addResponse(Response<dynamic>(
    requestOptions: ok,
    statusCode: 200,
    data: {'items': List.generate(3, (i) => {'id': i})},
    headers: Headers.fromMap({
      'content-type': ['application/json'],
      'x-request-id': ['9f2c1a44-0d8e-4b6a-9d21-77b0c1f2ee31'],
    }),
  ));

  final failed = RequestOptions(
    path: '/api/v1/appointments/confirm',
    baseUrl: 'https://hospital-management-system.example.com',
    method: 'POST',
    data: {'note': "it's a very long note that must not overflow " * 4},
  );
  storage.addRequest(failed);
  storage.addError(DioException(
    requestOptions: failed,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: failed,
      statusCode: 422,
      data: {'detail': 'Validation failed because the payload is invalid ' * 3},
    ),
  ));

  storage.addRequest(RequestOptions(
    path: '/api/v1/notifications/stream',
    baseUrl: 'https://hospital-management-system.example.com',
    method: 'DELETE',
  ));
}

Widget _host(Widget child, {double textScale = 1.0}) => MaterialApp(
      debugShowCheckedModeBanner: false,
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

  Future<void> shot(
    WidgetTester tester,
    Widget page,
    Size size,
    String name, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(page, textScale: textScale));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('list phone', (t) => shot(t, const DebugPage(), const Size(390, 844), 'list_phone'));
  testWidgets('list small', (t) => shot(t, const DebugPage(), const Size(320, 640), 'list_small'));
  testWidgets('list tablet', (t) => shot(t, const DebugPage(), const Size(834, 1112), 'list_tablet'));
  testWidgets('list bigfont', (t) => shot(t, const DebugPage(), const Size(320, 640), 'list_bigfont', textScale: 2.0));
  testWidgets('stats phone', (t) => shot(t, const DebugStats(), const Size(390, 844), 'stats_phone'));
  testWidgets('stats tablet', (t) => shot(t, const DebugStats(), const Size(834, 1112), 'stats_tablet'));

  testWidgets('detail error', (tester) async {
    final model = DebugStorage().requests.firstWhere((r) => r.hasError);
    await shot(tester, DebugDetail(debugModel: model), const Size(390, 844), 'detail_error');
  });

  testWidgets('detail ok', (tester) async {
    final model = DebugStorage().requests.firstWhere((r) => r.isSuccess);
    await shot(tester, DebugDetail(debugModel: model), const Size(390, 844), 'detail_ok');
  });
}
