import 'package:dio/dio.dart';

import '../storage/debug_model.dart';
import 'log_formatter.dart';

/// Sorğunu müxtəlif formatlarda mətnə çevirir.
class CopyHelper {
  const CopyHelper._();

  /// Shell üçün təhlükəsiz tək dırnaqlı sətir.
  static String _shellQuote(String value) =>
      "'${value.replaceAll("'", r"'\''")}'";

  static String generateCurlCommand(DebugModel model, {bool redact = false}) {
    final buffer = StringBuffer('curl -X ${model.httpMethod}');

    model.requestHeadersView(redact: redact).forEach((key, value) {
      buffer.write(" \\\n  -H ${_shellQuote('$key: $value')}");
    });

    final body = model.requestData;
    if (body != null) {
      if (body is FormData) {
        for (final field in body.fields) {
          buffer.write(" \\\n  -F ${_shellQuote('${field.key}=${field.value}')}");
        }
        for (final file in body.files) {
          buffer.write(
            " \\\n  -F ${_shellQuote('${file.key}=@${file.value.filename ?? 'file'}')}",
          );
        }
      } else {
        final encoded = body is String ? body : LogFormatter.encode(body);
        buffer.write(" \\\n  -d ${_shellQuote(encoded)}");
      }
    }

    buffer.write(" \\\n  ${_shellQuote(model.url)}");
    return buffer.toString();
  }

  static String generatePostmanJson(DebugModel model, {bool redact = false}) {
    final uri = model.uri;
    final collection = <String, dynamic>{
      'info': <String, dynamic>{
        'name': model.shortPath,
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': <dynamic>[
        <String, dynamic>{
          'name': model.shortPath,
          'request': <String, dynamic>{
            'method': model.httpMethod,
            'header': model
                .requestHeadersView(redact: redact)
                .entries
                .map((e) => <String, dynamic>{
                      'key': e.key,
                      'value': e.value,
                      'type': 'text',
                    })
                .toList(),
            'body': <String, dynamic>{
              'mode': 'raw',
              'raw': LogFormatter.pretty(model.requestData),
              'options': <String, dynamic>{
                'raw': <String, dynamic>{'language': 'json'},
              },
            },
            'url': <String, dynamic>{
              'raw': model.url,
              'protocol': uri.scheme,
              'host': uri.host.split('.'),
              if (uri.hasPort) 'port': '${uri.port}',
              'path': uri.pathSegments,
              if (uri.hasQuery)
                'query': uri.queryParameters.entries
                    .map((e) => <String, dynamic>{
                          'key': e.key,
                          'value': e.value,
                        })
                    .toList(),
            },
          },
          'response': <dynamic>[],
        },
      ],
    };

    return LogFormatter.pretty(collection);
  }

  static String generateJsonRequest(DebugModel model, {bool redact = false}) =>
      LogFormatter.pretty(model.toJson(redact: redact));

  /// Yalnız response body.
  static String generateResponseBody(DebugModel model) =>
      LogFormatter.pretty(model.responseData);

  /// Sorğu + cavabın oxunaqlı mətn xülasəsi (bug report üçün).
  static String generateSummary(DebugModel model, {bool redact = true}) {
    final buffer = StringBuffer()
      ..writeln('${model.httpMethod} ${model.url}')
      ..writeln('Status : ${model.statusCode} (${model.statusLabel})')
      ..writeln('Time   : ${model.requestTimeString}')
      ..writeln('Took   : ${model.elapsedTimeInMs}')
      ..writeln('Size   : ↑ ${model.requestSizeLabel} · ↓ ${model.responseSizeLabel}')
      ..writeln()
      ..writeln('--- Request headers ---')
      ..writeln(LogFormatter.pretty(model.requestHeadersView(redact: redact)));

    if (model.hasRequestData) {
      buffer
        ..writeln()
        ..writeln('--- Request body ---')
        ..writeln(LogFormatter.pretty(model.requestData));
    }

    if (model.hasError) {
      buffer
        ..writeln()
        ..writeln('--- Error ---')
        ..writeln(model.errorStatusMessage);
      final underlying = model.underlyingError;
      if (underlying != null) buffer.writeln(underlying);
    }

    if (model.hasResponseData) {
      buffer
        ..writeln()
        ..writeln('--- Response body ---')
        ..writeln(LogFormatter.pretty(model.responseData));
    }

    return buffer.toString();
  }
}
