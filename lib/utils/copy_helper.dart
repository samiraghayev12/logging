import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logging_service/storage/debug_model.dart';

class CopyHelper {
  static String generateCurlCommand(DebugModel model) {
    final method = model.httpMethod;
    final url = model.url;
    final headers = model.requestHeaders;
    final body = model.requestData;

    StringBuffer curl = StringBuffer('curl -X $method');

    // Add headers
    headers.forEach((key, value) {
      curl.write(" \\\n  -H '$key: $value'");
    });

    // Add body if exists
    if (body != null && body is! FormData) {
      final bodyJson = jsonEncode(body);
      curl.write(" \\\n  -d '$bodyJson'");
    }

    curl.write(" \\\n  '$url'");

    return curl.toString();
  }

  static String generatePostmanJson(DebugModel model) {
    final postmanRequest = {
      "info": {
        "name": model.path,
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
      },
      "item": [
        {
          "name": model.path,
          "request": {
            "method": model.httpMethod,
            "header": model.requestHeaders.entries
                .map((e) => {
                      "key": e.key,
                      "value": e.value,
                      "type": "text"
                    })
                .toList(),
            "body": {
              "mode": "raw",
              "raw": jsonEncode(model.requestData ?? {}),
              "options": {"raw": {"language": "json"}}
            },
            "url": model.url
          },
          "response": []
        }
      ]
    };

    return jsonEncode(postmanRequest);
  }

  static String generateJsonRequest(DebugModel model) {
    final request = {
      "method": model.httpMethod,
      "url": model.url,
      "headers": model.requestHeaders,
      "body": model.requestData,
      "timestamp": model.requestTime,
      "elapsedTime": "${model.elapsedTime}ms"
    };

    return jsonEncode(request);
  }
}
