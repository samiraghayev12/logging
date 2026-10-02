import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';
import 'package:flutter/material.dart';

import 'mock_api.dart';

void main() {
  // Optional: make the "Retry" button in the logger use the fake API too.
  DioDebugLogger.retryClientBuilder =
      () => Dio()..httpClientAdapter = MockApiAdapter();

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dio_debug_logger demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // Setup step 2 of 2: the draggable debug button (debug builds only).
      builder: DioDebugLogger.builder(),
      home: const DemoPage(),
    );
  }
}

/// The app's API client.
class Api {
  String? token;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com/v1',
      headers: {'Accept': 'application/json', 'X-App-Version': '1.0.0'},
    ),
  )
    // A fake server inside the app, so the demo works offline.
    // Remove this line in a real app.
    ..httpClientAdapter = MockApiAdapter()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
          }
          handler.next(options);
        },
      ),
    )
    // Setup step 1 of 2: record every request of this Dio.
    ..addDebugLogger();
}

class Scenario {
  const Scenario(this.method, this.path, this.title, this.run);

  final String method;
  final String path;
  final String title;
  final Future<Response<dynamic>> Function(Api api) run;
}

final List<(String, List<Scenario>)> scenarioGroups = [
  (
    'Auth & tokens',
    [
      Scenario('POST', '/auth/login', 'Login → access token', (api) async {
        final res = await api.dio.post<dynamic>(
          '/auth/login',
          data: {'email': 'demo@example.com', 'password': 'secret123'},
        );
        api.token = res.data['access_token'] as String;
        return res;
      }),
      Scenario('POST', '/auth/login', 'Wrong password → 401', (api) {
        return api.dio.post<dynamic>(
          '/auth/login',
          data: {'email': 'demo@example.com', 'password': 'wrong'},
        );
      }),
      Scenario('GET', '/me', 'Profile (Bearer token)', (api) {
        return api.dio.get<dynamic>('/me');
      }),
      Scenario('GET', '/me', 'Expired token → 401', (api) {
        return api.dio.get<dynamic>(
          '/me',
          options: Options(
            headers: {'Authorization': 'Bearer ${MockApiAdapter.expiredToken}'},
          ),
        );
      }),
      Scenario('POST', '/auth/refresh', 'Refresh token', (api) {
        return api.dio.post<dynamic>(
          '/auth/refresh',
          data: {'refresh_token': 'rt_8f2a1c9e7b6d4a3f'},
        );
      }),
    ],
  ),
  (
    'CRUD',
    [
      Scenario('GET', '/users?page=1&limit=5', 'List users (query params)', (api) {
        return api.dio.get<dynamic>(
          '/users',
          queryParameters: {'page': 1, 'limit': 5},
        );
      }),
      Scenario('GET', '/users/7', 'Get one user', (api) {
        return api.dio.get<dynamic>('/users/7');
      }),
      Scenario('POST', '/users', 'Create user → 201', (api) {
        return api.dio.post<dynamic>(
          '/users',
          data: {'name': 'Kamran Rzayev', 'email': 'kamran@example.com', 'role': 'user'},
        );
      }),
      Scenario('PUT', '/users/7', 'Replace user', (api) {
        return api.dio.put<dynamic>(
          '/users/7',
          data: {'name': 'Leyla Hasanova', 'email': 'leyla@example.com', 'role': 'editor'},
        );
      }),
      Scenario('PATCH', '/users/7', 'Update one field', (api) {
        return api.dio.patch<dynamic>('/users/7', data: {'role': 'admin'});
      }),
      Scenario('DELETE', '/users/7', 'Delete user → 204', (api) {
        return api.dio.delete<dynamic>('/users/7');
      }),
    ],
  ),
  (
    'Bodies & timing',
    [
      Scenario('GET', '/products?category=…', 'Search with filters', (api) {
        return api.dio.get<dynamic>(
          '/products',
          queryParameters: {'category': 'Phones', 'sort': 'price_asc', 'inStock': true},
        );
      }),
      Scenario('GET', '/posts', 'Large response (100 items)', (api) {
        return api.dio.get<dynamic>('/posts');
      }),
      Scenario('POST', '/upload', 'Multipart upload (FormData)', (api) {
        return api.dio.post<dynamic>(
          '/upload',
          data: FormData.fromMap({
            'userId': '42',
            'description': 'Profile photo',
            'file': MultipartFile.fromBytes(
              List<int>.generate(2048, (i) => i % 256),
              filename: 'avatar.png',
              contentType: DioMediaType('image', 'png'),
            ),
          }),
        );
      }),
      Scenario('GET', '/reports/slow', 'Slow request (3 s, pending)', (api) {
        return api.dio.get<dynamic>('/reports/slow');
      }),
    ],
  ),
  (
    'HTTP errors',
    [
      Scenario('POST', '/orders', '400 Validation errors', (api) {
        return api.dio.post<dynamic>(
          '/orders',
          data: {'email': 'not-an-email', 'quantity': 0},
        );
      }),
      Scenario('GET', '/admin/settings', '403 Forbidden', (api) {
        return api.dio.get<dynamic>('/admin/settings');
      }),
      Scenario('GET', '/users/999', '404 Not found', (api) {
        return api.dio.get<dynamic>('/users/999');
      }),
      Scenario('POST', '/users/conflict', '409 Conflict', (api) {
        return api.dio.post<dynamic>(
          '/users/conflict',
          data: {'email': 'aysel1@example.com'},
        );
      }),
      Scenario('POST', '/payments', '422 Problem+JSON', (api) {
        return api.dio.post<dynamic>(
          '/payments',
          data: {'amount': 50.0, 'currency': 'AZN'},
        );
      }),
      Scenario('GET', '/rate-limited', '429 Too many requests', (api) {
        return api.dio.get<dynamic>('/rate-limited');
      }),
      Scenario('GET', '/crash', '500 Server error', (api) {
        return api.dio.get<dynamic>('/crash');
      }),
      Scenario('GET', '/maintenance', '503 Plain-text error', (api) {
        return api.dio.get<dynamic>('/maintenance');
      }),
    ],
  ),
  (
    'Network failures',
    [
      Scenario('GET', '/timeout', 'Connection timeout', (api) {
        return api.dio.get<dynamic>('/timeout');
      }),
      Scenario('GET', '/offline', 'No internet (DNS error)', (api) {
        return api.dio.get<dynamic>('/offline');
      }),
      Scenario('GET', '/cancellable', 'Cancelled by user', (api) {
        final cancelToken = CancelToken();
        Timer(const Duration(seconds: 1), cancelToken.cancel);
        return api.dio.get<dynamic>('/cancellable', cancelToken: cancelToken);
      }),
    ],
  ),
];

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _api = Api();
  bool _runningAll = false;

  Future<void> _run(Scenario scenario, {bool showResult = true}) async {
    String result;
    var isError = false;
    try {
      final res = await scenario.run(_api);
      result = '${res.statusCode} ${res.statusMessage ?? ''}';
    } on DioException catch (e) {
      isError = true;
      result = e.response != null
          ? '${e.response!.statusCode} ${e.response!.statusMessage ?? ''}'
          : e.type.name;
    }
    if (!mounted) return;
    setState(() {});
    if (!showResult) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
          content: Text('${scenario.method} ${scenario.path}  →  $result'),
        ),
      );
  }

  /// Fires every scenario with a small stagger — good for a quick demo.
  Future<void> _runAll() async {
    setState(() => _runningAll = true);
    final all = [for (final group in scenarioGroups) ...group.$2];
    await _run(all.first, showResult: false); // login first, so a token exists
    final pending = <Future<void>>[];
    for (final scenario in all.skip(1)) {
      pending.add(_run(scenario, showResult: false));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    await Future.wait(pending);
    if (mounted) setState(() => _runningAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('dio_debug_logger demo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _api.token != null ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: _api.token != null ? Colors.green : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _api.token != null
                              ? 'Logged in — token: ${_api.token!.substring(0, 16)}…'
                              : 'Not logged in',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap any request below, then open the logs with the draggable 🐞 button.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _runningAll ? null : _runAll,
                        icon: _runningAll
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: const Text('Run all'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => DioDebugLogger.open(context),
                        icon: const Icon(Icons.list_alt_rounded),
                        label: const Text('Open logs'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          DioDebugLogger.storage.clear();
                          setState(() => _api.token = null);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (final (title, scenarios) in scenarioGroups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            for (final scenario in scenarios)
              _ScenarioTile(scenario: scenario, onTap: () => _run(scenario)),
          ],
        ],
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario, required this.onTap});

  final Scenario scenario;
  final VoidCallback onTap;

  static const _methodColors = {
    'GET': Colors.blue,
    'POST': Colors.green,
    'PUT': Colors.orange,
    'PATCH': Colors.purple,
    'DELETE': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _methodColors[scenario.method] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            scenario.method,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        title: Text(scenario.title),
        subtitle: Text(scenario.path, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.send_rounded, size: 18),
      ),
    );
  }
}
