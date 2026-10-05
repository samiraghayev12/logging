import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'redaction.dart';

/// Safely converts log content to text / JSON.
///
/// No method throws — a debug tool must never crash the app.
class LogFormatter {
  const LogFormatter._();

  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  /// Common secret header names. Masking uses [Redaction.isSensitive], which
  /// covers these and more.
  static const Set<String> sensitiveHeaders = {
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
    'x-auth-token',
    'refresh-token',
    'access-token',
  };

  /// Converts any value to a JSON-compatible structure.
  static Object? sanitize(Object? value, {int depth = 0}) {
    if (depth > 24) return value.toString();
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Uint8List) return '<binary ${humanBytes(value.length)}>';
    if (value is FormData) return formDataToMap(value);
    if (value is MultipartFile) {
      return '<file ${value.filename ?? 'unnamed'} · ${humanBytes(value.length)}>';
    }
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, dynamic item) {
        result['$key'] = sanitize(item, depth: depth + 1);
      });
      return result;
    }
    if (value is Iterable) {
      return value.map((dynamic e) => sanitize(e, depth: depth + 1)).toList();
    }
    try {
      // ignore: avoid_dynamic_calls
      return sanitize((value as dynamic).toJson() as Object?, depth: depth + 1);
    } catch (_) {
      return value.toString();
    }
  }

  /// Structure for the JSON viewer. Parses strings that contain JSON.
  static Object? forJsonView(Object? value) {
    if (value is String) {
      final decoded = tryDecode(value);
      if (decoded != null) return sanitize(decoded);
      return value;
    }
    return sanitize(value);
  }

  /// Decodes a JSON string, otherwise returns `null`.
  static Object? tryDecode(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;
    final first = trimmed.codeUnitAt(0);
    // only check strings starting with `{` or `[`
    if (first != 0x7B && first != 0x5B) return null;
    try {
      return jsonDecode(trimmed) as Object?;
    } catch (_) {
      return null;
    }
  }

  /// Compact JSON string.
  static String encode(Object? value) {
    try {
      return jsonEncode(sanitize(value));
    } catch (_) {
      return '${value ?? ''}';
    }
  }

  /// Indented (readable) JSON string.
  static String pretty(Object? value) {
    if (value == null) return '';
    try {
      return _prettyEncoder.convert(forJsonView(value));
    } catch (_) {
      return '$value';
    }
  }

  static Map<String, dynamic> formDataToMap(FormData formData) {
    final fields = <String, dynamic>{};
    for (final entry in formData.fields) {
      final existing = fields[entry.key];
      if (existing == null) {
        fields[entry.key] = entry.value;
      } else if (existing is List) {
        existing.add(entry.value);
      } else {
        fields[entry.key] = <dynamic>[existing, entry.value];
      }
    }

    final files = <Map<String, dynamic>>[];
    for (final entry in formData.files) {
      files.add(<String, dynamic>{
        'field': entry.key,
        'filename': entry.value.filename,
        'contentType': entry.value.contentType?.toString(),
        'size': humanBytes(entry.value.length),
      });
    }

    return <String, dynamic>{
      if (fields.isNotEmpty) 'fields': fields,
      if (files.isNotEmpty) 'files': files,
    };
  }

  /// Normalizes a header map to `Map<String, String>` (values may be a `List`).
  static Map<String, String> normalizeHeaders(
    Map<String, dynamic> headers, {
    bool redact = false,
  }) {
    final result = <String, String>{};
    headers.forEach((key, dynamic value) {
      final stringValue = value is Iterable
          ? value.map((dynamic e) => '$e').join(', ')
          : '$value';
      result[key] = redact && Redaction.isSensitive(key)
          ? Redaction.mask
          : stringValue;
    });
    return result;
  }

  /// Approximate size of the data in bytes, or `null` if unknown.
  static int? byteSize(Object? value) {
    if (value == null) return null;
    try {
      if (value is String) return utf8.encode(value).length;
      if (value is Uint8List) return value.length;
      if (value is List<int>) return value.length;
      if (value is FormData) return value.length;
      return utf8.encode(encode(value)).length;
    } catch (_) {
      return null;
    }
  }

  static String humanBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// `14:32:07.482` format.
  static String clockTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// `08.09.2026 14:32:07` format.
  static String dateTimeLabel(DateTime time) {
    final d = time.day.toString().padLeft(2, '0');
    final mo = time.month.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final mi = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$d.$mo.${time.year} $h:$mi:$s';
  }
}
