import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Masks secrets (passwords, tokens, keys…) in headers, bodies and URLs.
///
/// Used for the console, the log UI, copying and exporting. The UI can show
/// the real values on demand with [reveal] (the eye icon); it is reset on
/// every app start.
class Redaction {
  const Redaction._();

  static const String mask = '••••••';

  /// Key fragments that mark a value as secret. Compared case-insensitively,
  /// ignoring `_`, `-`, `.` and spaces, so `access_token`, `X-Api-Key` and
  /// `clientSecret` all match.
  static const Set<String> _fragments = {
    'password',
    'passwd',
    'passcode',
    'secret',
    'token',
    'apikey',
    'authorization',
    'cookie',
    'credential',
    'privatekey',
    'signature',
  };

  /// Keys that only match exactly (too short to match as fragments).
  static const Set<String> _exact = {
    'pin',
    'otp',
    'cvv',
    'cvc',
    'ssn',
    'pan',
    'cardnumber',
    'sessionid',
    'session',
    'auth',
  };

  /// Extra keys to mask, e.g. `{'national_id', 'iban'}`. Matched like the
  /// built-in ones (case and separators are ignored).
  static final Set<String> extraKeys = {};

  /// Whether the log UI shows real values instead of masks.
  static final ValueNotifier<bool> reveal = ValueNotifier<bool>(false);

  static String _normalize(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[\s_\-.]'), '');

  /// Whether a header, body field or query parameter named [key] is secret.
  static bool isSensitive(String key) {
    final k = _normalize(key);
    if (k.isEmpty) return false;
    if (_exact.contains(k)) return true;
    if (extraKeys.any((extra) => _normalize(extra) == k)) return true;
    return _fragments.any(k.contains);
  }

  /// Returns a copy of [data] with secret values masked. JSON strings stay
  /// strings, `FormData` becomes a map. Never throws.
  static Object? redact(Object? data, {int depth = 0}) {
    try {
      return _redact(data, depth);
    } catch (_) {
      return mask;
    }
  }

  static Object? _redact(Object? data, int depth) {
    if (depth > 24) return mask;
    if (data is Map) {
      return <String, dynamic>{
        for (final entry in data.entries)
          '${entry.key}': isSensitive('${entry.key}') && entry.value != null
              ? mask
              : _redact(entry.value, depth + 1),
      };
    }
    if (data is Iterable && data is! String) {
      return [for (final item in data) _redact(item, depth + 1)];
    }
    if (data is FormData) {
      return <String, dynamic>{
        for (final field in data.fields)
          field.key: isSensitive(field.key) ? mask : field.value,
        for (final file in data.files)
          file.key: '<file ${file.value.filename ?? 'unnamed'}>',
      };
    }
    if (data is String) {
      final trimmed = data.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonEncode(_redact(jsonDecode(data), depth + 1));
        } catch (_) {
          return data;
        }
      }
      if (_looksLikeForm(data)) return _redactQueryString(data);
    }
    return data;
  }

  static bool _looksLikeForm(String value) =>
      RegExp(r'^[\w.\-%]+=[^&\s]*(&[\w.\-%]+=[^&\s]*)*$').hasMatch(value);

  static String _redactQueryString(String value) {
    return value
        .split('&')
        .map((pair) {
          final i = pair.indexOf('=');
          if (i <= 0) return pair;
          final key = Uri.decodeQueryComponent(pair.substring(0, i));
          return isSensitive(key) ? '${pair.substring(0, i)}=$mask' : pair;
        })
        .join('&');
  }

  /// Masks headers. Values may be strings or lists.
  static Map<String, String> headers(Map<String, String> headers) => {
    for (final entry in headers.entries)
      entry.key: isSensitive(entry.key) ? mask : entry.value,
  };

  /// Masks secret query parameters in [url].
  static String url(String url) {
    final start = url.indexOf('?');
    if (start < 0) return url;
    final hash = url.indexOf('#', start);
    final end = hash < 0 ? url.length : hash;
    final query = _redactQueryString(url.substring(start + 1, end));
    return '${url.substring(0, start + 1)}$query${url.substring(end)}';
  }

  /// [data] masked unless [reveal] is on. For the log UI.
  static Object? forDisplay(Object? data) => reveal.value ? data : redact(data);

  /// [url] masked unless [reveal] is on. For the log UI.
  static String urlForDisplay(String value) =>
      reveal.value ? value : url(value);
}
