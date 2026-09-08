import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging_service/logging_service.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'logging_service example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // İnteqrasiyanın tək sətri.
      builder: NetworkLogger.overlayBuilder(),
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
        'X-Client': 'logging_service-example',
      },
    ),
  )..interceptors.add(DebugLogging());

  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      // Loglara düşür — burada udmaq kifayətdir.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('logging_service example')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text(
            'Aşağıdakı sorğuları işə sal, sonra sürüklənən 🐞 düyməsinə bas.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          _Action(
            label: 'GET /posts/1',
            enabled: !_busy,
            onTap: () => _run(() => _dio.get<dynamic>('/posts/1')),
          ),
          _Action(
            label: 'GET /posts (böyük cavab)',
            enabled: !_busy,
            onTap: () => _run(() => _dio.get<dynamic>('/posts')),
          ),
          _Action(
            label: 'POST /posts (body ilə)',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio.post<dynamic>(
                '/posts',
                data: {
                  'title': "it's a test",
                  'body': 'Uzun mətn ' * 20,
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
            label: '404 xətası',
            enabled: !_busy,
            onTap: () => _run(() => _dio.get<dynamic>('/does-not-exist')),
          ),
          _Action(
            label: 'Şəbəkə xətası (DNS)',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio.get<dynamic>('https://this-host-does-not-exist.invalid/x'),
            ),
          ),
          _Action(
            label: 'Timeout (1ms)',
            enabled: !_busy,
            onTap: () => _run(
              () => _dio.get<dynamic>(
                '/posts',
                options: Options(receiveTimeout: const Duration(milliseconds: 1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => NetworkLogger.open(context),
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Logları proqramla aç'),
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
