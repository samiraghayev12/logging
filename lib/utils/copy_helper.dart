import 'package:dio/dio.dart';

import '../storage/debug_model.dart';
import 'log_formatter.dart';
import 'redaction.dart';

/// Converts a request to text in various formats.
class CopyHelper {
  const CopyHelper._();

  /// Shell-safe single-quoted string.
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
          final value = redact && Redaction.isSensitive(field.key)
              ? Redaction.mask
              : field.value;
          buffer.write(" \\\n  -F ${_shellQuote('${field.key}=$value')}");
        }
        for (final file in body.files) {
          buffer.write(
            " \\\n  -F ${_shellQuote('${file.key}=@${file.value.filename ?? 'file'}')}",
          );
        }
      } else {
        final data = redact ? Redaction.redact(body) : body;
        final encoded = data is String ? data : LogFormatter.encode(data);
        buffer.write(" \\\n  -d ${_shellQuote(encoded)}");
      }
    }

    buffer.write(
      " \\\n  ${_shellQuote(redact ? Redaction.url(model.url) : model.url)}",
    );
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
                .map(
                  (e) => <String, dynamic>{
                    'key': e.key,
                    'value': e.value,
                    'type': 'text',
                  },
                )
                .toList(),
            'body': <String, dynamic>{
              'mode': 'raw',
              'raw': LogFormatter.pretty(
                redact
                    ? Redaction.redact(model.requestData)
                    : model.requestData,
              ),
              'options': <String, dynamic>{
                'raw': <String, dynamic>{'language': 'json'},
              },
            },
            'url': <String, dynamic>{
              'raw': redact ? Redaction.url(model.url) : model.url,
              'protocol': uri.scheme,
              'host': uri.host.split('.'),
              if (uri.hasPort) 'port': '${uri.port}',
              'path': uri.pathSegments,
              if (uri.hasQuery)
                'query': uri.queryParameters.entries
                    .map(
                      (e) => <String, dynamic>{
                        'key': e.key,
                        'value': redact && Redaction.isSensitive(e.key)
                            ? Redaction.mask
                            : e.value,
                      },
                    )
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

  /// Response body only.
  static String generateResponseBody(DebugModel model, {bool redact = true}) =>
      LogFormatter.pretty(
        redact ? Redaction.redact(model.responseData) : model.responseData,
      );

  /// Readable summary of the request and response (for bug reports).
  static String generateSummary(DebugModel model, {bool redact = true}) {
    final buffer = StringBuffer()
      ..writeln(
        '${model.httpMethod} ${redact ? Redaction.url(model.url) : model.url}',
      )
      ..writeln('Status : ${model.statusCode} (${model.statusLabel})')
      ..writeln('Time   : ${model.requestTimeString}')
      ..writeln('Took   : ${model.elapsedTimeInMs}')
      ..writeln(
        'Size   : ↑ ${model.requestSizeLabel} · ↓ ${model.responseSizeLabel}',
      )
      ..writeln()
      ..writeln('--- Request headers ---')
      ..writeln(LogFormatter.pretty(model.requestHeadersView(redact: redact)));

    if (model.hasRequestData) {
      buffer
        ..writeln()
        ..writeln('--- Request body ---')
        ..writeln(
          LogFormatter.pretty(
            redact ? Redaction.redact(model.requestData) : model.requestData,
          ),
        );
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
        ..writeln(
          LogFormatter.pretty(
            redact ? Redaction.redact(model.responseData) : model.responseData,
          ),
        );
    }

    return buffer.toString();
  }
}
