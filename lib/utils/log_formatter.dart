import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Log məzmununu təhlükəsiz şəkildə mətnə / JSON-a çevirir.
///
/// Bütün metodlar exception atmır — debug aləti heç vaxt appi çökdürməməlidir.
class LogFormatter {
  const LogFormatter._();

  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  /// Gizlədilməli header adları (kiçik hərflə müqayisə olunur).
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

  /// İstənilən dəyəri JSON-a uyğun struktura çevirir.
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

  /// JSON viewer-ə veriləcək struktur. String JSON-dursa parse edir.
  static Object? forJsonView(Object? value) {
    if (value is String) {
      final decoded = tryDecode(value);
      if (decoded != null) return sanitize(decoded);
      return value;
    }
    return sanitize(value);
  }

  /// String JSON-dursa decode edir, əks halda `null` qaytarır.
  static Object? tryDecode(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;
    final first = trimmed.codeUnitAt(0);
    // yalnız `{` və ya `[` ilə başlayanları yoxla
    if (first != 0x7B && first != 0x5B) return null;
    try {
      return jsonDecode(trimmed) as Object?;
    } catch (_) {
      return null;
    }
  }

  /// Sətir formasında, sıxılmış JSON.
  static String encode(Object? value) {
    try {
      return jsonEncode(sanitize(value));
    } catch (_) {
      return '${value ?? ''}';
    }
  }

  /// Sətir formasında, girintili (oxunaqlı) JSON.
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

  /// Header map-ini `Map<String, String>`-ə normallaşdırır (dəyər `List` ola bilər).
  static Map<String, String> normalizeHeaders(
    Map<String, dynamic> headers, {
    bool redact = false,
  }) {
    final result = <String, String>{};
    headers.forEach((key, dynamic value) {
      final stringValue = value is Iterable
          ? value.map((dynamic e) => '$e').join(', ')
          : '$value';
      result[key] = redact && sensitiveHeaders.contains(key.toLowerCase())
          ? _mask(stringValue)
          : stringValue;
    });
    return result;
  }

  static String _mask(String value) {
    if (value.length <= 8) return '••••••';
    return '${value.substring(0, 4)}••••${value.substring(value.length - 4)}';
  }

  /// Data-nın təxmini ölçüsü (bayt). Hesablana bilmirsə `null`.
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

  /// `14:32:07.482` formatı.
  static String clockTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// `08.09.2026 14:32:07` formatı.
  static String dateTimeLabel(DateTime time) {
    final d = time.day.toString().padLeft(2, '0');
    final mo = time.month.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final mi = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$d.$mo.${time.year} $h:$mi:$s';
  }
}
