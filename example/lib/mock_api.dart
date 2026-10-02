import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A fake REST API that runs inside the app — no internet needed.
///
/// Plug it into any Dio with `dio.httpClientAdapter = MockApiAdapter()`.
/// Every endpoint returns realistic data, headers, delays and errors so the
/// logger has something interesting to show.
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter();

  static const validToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0MiIsIm5hbWUiOiJEZW1vIn0.demo-signature';
  static const expiredToken = 'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MDAwMDAwMDB9.expired-signature';

  int _requestId = 1000;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Drain the body stream (FormData etc.) like a real server would.
    await requestStream?.drain<void>();

    final route = _route(options);
    await _wait(route.delay, options, cancelFuture);

    if (route.failure != null) throw route.failure!(options);

    final isText = route.body is String;
    return ResponseBody.fromString(
      route.body == null ? '' : (isText ? route.body as String : jsonEncode(route.body)),
      route.status,
      statusMessage: _statusMessages[route.status],
      headers: {
        if (route.body != null)
          Headers.contentTypeHeader: [
            route.contentType ??
                (isText ? 'text/plain; charset=utf-8' : 'application/json; charset=utf-8'),
          ],
        'x-request-id': ['req_${_requestId++}'],
        'x-ratelimit-remaining': ['${59 - (_requestId % 60)}'],
        'server': ['mock-api/1.0'],
        ...route.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Future<void> _wait(
    Duration delay,
    RequestOptions options,
    Future<void>? cancelFuture,
  ) async {
    final timer = Future<void>.delayed(delay);
    if (cancelFuture == null) return timer;
    final cancelled = await Future.any([
      timer.then((_) => false),
      cancelFuture.then((_) => true),
    ]);
    if (cancelled) {
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: 'Cancelled by the user',
      );
    }
  }

  _Route _route(RequestOptions o) {
    final method = o.method.toUpperCase();
    final path = o.uri.path.replaceFirst('/v1', '');
    final auth = o.headers['Authorization'] as String?;
    final data = o.data;

    // ---------- Auth ----------
    if (method == 'POST' && path == '/auth/login') {
      final body = data is Map ? data : const {};
      if (body['password'] != 'secret123') {
        return _Route(401, {
          'error': 'invalid_credentials',
          'message': 'Email or password is incorrect',
        });
      }
      return _Route(
        200,
        {
          'access_token': validToken,
          'refresh_token': 'rt_8f2a1c9e7b6d4a3f',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'user': _user(42),
        },
        headers: {
          'set-cookie': ['session=abc123; HttpOnly; Secure; Path=/'],
        },
      );
    }
    if (method == 'POST' && path == '/auth/refresh') {
      return _Route(200, {'access_token': validToken, 'expires_in': 3600});
    }
    if (path == '/me') {
      if (auth == null) {
        return _Route(
          401,
          {'error': 'unauthorized', 'message': 'Missing Authorization header'},
          headers: {
            'www-authenticate': ['Bearer realm="api"'],
          },
        );
      }
      if (auth == 'Bearer $expiredToken') {
        return _Route(
          401,
          {'error': 'token_expired', 'message': 'Access token has expired'},
          headers: {
            'www-authenticate': ['Bearer error="invalid_token"'],
          },
        );
      }
      return _Route(200, _user(42));
    }

    // ---------- Users CRUD ----------
    final userMatch = RegExp(r'^/users/(\d+)$').firstMatch(path);
    if (path == '/users' && method == 'GET') {
      final page = int.tryParse('${o.queryParameters['page'] ?? 1}') ?? 1;
      final limit = int.tryParse('${o.queryParameters['limit'] ?? 10}') ?? 10;
      return _Route(200, {
        'page': page,
        'limit': limit,
        'total': 48,
        'data': [for (var i = 0; i < limit; i++) _user((page - 1) * limit + i + 1)],
      });
    }
    if (path == '/users' && method == 'POST') {
      return _Route(
        201,
        {'id': 49, ...?(data as Map?)?.cast<String, dynamic>(), 'createdAt': _now()},
        headers: {
          'location': ['/v1/users/49'],
        },
      );
    }
    if (userMatch != null) {
      final id = int.parse(userMatch.group(1)!);
      if (id > 48) {
        return _Route(404, {'error': 'not_found', 'message': 'User $id not found'});
      }
      switch (method) {
        case 'GET':
          return _Route(200, _user(id));
        case 'PUT':
          return _Route(200, {
            'id': id,
            ...?(data as Map?)?.cast<String, dynamic>(),
            'updatedAt': _now(),
          });
        case 'PATCH':
          return _Route(200, {
            ..._user(id),
            ...?(data as Map?)?.cast<String, dynamic>(),
            'updatedAt': _now(),
          });
        case 'DELETE':
          return _Route(204, null);
      }
    }

    // ---------- Misc ----------
    if (path == '/products' && method == 'GET') {
      final q = o.queryParameters;
      return _Route(200, {
        'filters': q,
        'items': [
          for (var i = 1; i <= 6; i++)
            {
              'id': 'p_$i',
              'name': '${q['category'] ?? 'Item'} #$i',
              'price': 99.9 * i,
              'inStock': i.isEven,
            },
        ],
      });
    }
    if (path == '/posts' && method == 'GET') {
      return _Route(
        200,
        [
          for (var i = 1; i <= 100; i++)
            {
              'id': i,
              'userId': (i % 10) + 1,
              'title': 'Post title number $i',
              'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 3,
              'tags': ['flutter', 'dio', if (i.isEven) 'demo'],
            },
        ],
      );
    }
    if (path == '/upload' && method == 'POST') {
      final form = data is FormData ? data : null;
      return _Route(201, {
        'fields': {for (final f in form?.fields ?? <MapEntry<String, String>>[]) f.key: f.value},
        'files': [
          for (final f in form?.files ?? <MapEntry<String, MultipartFile>>[])
            {'field': f.key, 'filename': f.value.filename, 'size': f.value.length},
        ],
        'url': 'https://cdn.example.com/uploads/avatar_42.png',
      });
    }
    if (path == '/reports/slow') {
      return _Route(
        200,
        {'report': 'monthly', 'rows': 1240, 'generatedIn': '3.0s'},
        delay: const Duration(seconds: 3),
      );
    }

    // ---------- Errors ----------
    if (path == '/orders' && method == 'POST') {
      return _Route(400, {
        'message': 'Validation failed',
        'errors': {
          'email': ['Email is not valid'],
          'quantity': ['Must be greater than 0'],
        },
      });
    }
    if (path == '/admin/settings') {
      return _Route(403, {'error': 'forbidden', 'message': 'Admin role required'});
    }
    if (path == '/users/conflict') {
      return _Route(409, {'error': 'conflict', 'message': 'Email already exists'});
    }
    if (path == '/payments') {
      return _Route(
        422,
        {
          'type': 'https://example.com/problems/insufficient-funds',
          'title': 'Insufficient funds',
          'status': 422,
          'detail': 'Your balance is 30.00, but the payment requires 50.00',
        },
        contentType: 'application/problem+json',
      );
    }
    if (path == '/rate-limited') {
      return _Route(
        429,
        {'error': 'too_many_requests', 'message': 'Rate limit exceeded, retry in 30s'},
        headers: {
          'retry-after': ['30'],
        },
      );
    }
    if (path == '/crash') {
      return _Route(500, {
        'error': 'internal_error',
        'message': 'NullPointerException at OrderService.java:118',
        'traceId': 'trace_7d1e9a',
      });
    }
    if (path == '/maintenance') {
      return _Route(503, 'Service temporarily unavailable. Please try again later.');
    }

    // ---------- Network failures ----------
    if (path == '/timeout') {
      return _Route.fail(
        (o) => DioException.connectionTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: o,
        ),
        delay: const Duration(milliseconds: 1500),
      );
    }
    if (path == '/offline') {
      return _Route.fail(
        (o) => DioException.connectionError(
          requestOptions: o,
          reason: 'Failed host lookup: api.example.com (No address associated with hostname)',
        ),
      );
    }
    if (path == '/cancellable') {
      return _Route(200, {'ok': true}, delay: const Duration(seconds: 5));
    }

    return _Route(404, {
      'error': 'not_found',
      'message': 'No route for $method $path',
    });
  }

  static Map<String, dynamic> _user(int id) => {
        'id': id,
        'name': _names[id % _names.length],
        'email': '${_names[id % _names.length].split(' ').first.toLowerCase()}$id@example.com',
        'role': id == 42 ? 'admin' : 'user',
        'address': {'city': 'Baku', 'country': 'AZ'},
      };

  static String _now() => DateTime.now().toUtc().toIso8601String();

  static const _names = [
    'Aysel Mammadova',
    'Rashad Aliyev',
    'Leyla Hasanova',
    'Elvin Guliyev',
    'Nigar Huseynova',
    'Murad Ismayilov',
  ];

  static const _statusMessages = {
    200: 'OK',
    201: 'Created',
    204: 'No Content',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    409: 'Conflict',
    422: 'Unprocessable Entity',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
    503: 'Service Unavailable',
  };
}

class _Route {
  _Route(
    this.status,
    this.body, {
    this.headers = const {},
    this.contentType,
    Duration? delay,
  })  : delay = delay ?? Duration(milliseconds: 150 + _random.nextInt(650)),
        failure = null;

  static final _random = Random();

  _Route.fail(this.failure, {Duration? delay})
      : status = 0,
        body = null,
        headers = const {},
        contentType = null,
        delay = delay ?? const Duration(milliseconds: 600);

  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
  final String? contentType;
  final Duration delay;
  final DioException Function(RequestOptions)? failure;
}
