import 'package:dio/dio.dart';
import 'package:dio_debug_logger/dio_debug_logger.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dio_debug_logger example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // Setup step 2 of 2: show the debug button (debug builds only).
      builder: DioDebugLogger.builder(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer super-secret-token-value-1234567890',
        'X-Client': 'dio_debug_logger-example',
      },
    ),
  )..addDebugLogger(); // Setup step 1 of 2: record this Dio's requests.

  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      // The error is in the logs — nothing else to do here.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dio_debug_logger example')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text(
            'Send some requests below, then tap the draggable 🐞 button.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          _Action(
            label: 'GET /posts/1',
            enabled: !_busy,
            onTap: () => _run(() => _dio.get<dynamic>('/posts/1')),
          ),
          _Action(
            label: 'GET /posts (large response)',
            enabled: !_busy,
            onTap: () => _run(() => _dio.get<dynamic>('/posts')),
          ),
          _Action(
            label: 'POST /posts (with body)',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio.post<dynamic>(
                '/posts',
                data: {
                  'title': "it's a test",
                  'body': 'Long text ' * 20,
                  'userId': 1,
                },
              ),
            ),
          ),
          _Action(
            label: 'POST FormData',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio.post<dynamic>(
                '/posts',
                data: FormData.fromMap({'name': 'Samir', 'role': 'doctor'}),
              ),
            ),
          ),
          _Action(
            label: '404 error',
            enabled: !_busy,
            onTap: () => _run(() => _dio.get<dynamic>('/does-not-exist')),
          ),
          _Action(
            label: 'Network error (DNS)',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio
                  .get<dynamic>('https://this-host-does-not-exist.invalid/x'),
            ),
          ),
          _Action(
            label: 'Timeout (1ms)',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio.get<dynamic>(
                '/posts',
                options:
                    Options(receiveTimeout: const Duration(milliseconds: 1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => DioDebugLogger.open(context),
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Open logs from code'),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }
}
