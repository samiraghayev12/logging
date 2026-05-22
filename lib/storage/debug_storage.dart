import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugStorage extends ChangeNotifier {
  static final DebugStorage _singleton = DebugStorage._internal();
  factory DebugStorage() => _singleton;
  DebugStorage._internal();

  final List<DebugModel> _requests = [];
  int _counter = 0;

  /// Yaddaş limiti
  static const int _maxRequests = 200;

  /// Read-only liste — UI bunu görür
  List<DebugModel> get requests => List.unmodifiable(_requests);

  int get count => _requests.length;
  int get errorCount => _requests.where((r) => r.hasError).length;

  void addRequest(RequestOptions requestOptions) {
    final model = DebugModel(
      id: _counter++,
      requestOptions: requestOptions,
      requestStartTime: DateTime.now(),
    );
    _requests.insert(0, model);
    _trimIfNeeded();
    notifyListeners();
  }

  void addResponse(Response response) {
    final model = _findByRequestOptions(response.requestOptions);

    if (model != null) {
      model.response = response;
      _markCompleted(model);
    } else {
      // Orphan — request log olunmayıb
      _requests.insert(
          0,
          DebugModel(
            id: _counter++,
            requestOptions: response.requestOptions,
            requestStartTime: DateTime.now(),
            response: response,
            requestEndTime: DateTime.now(),
            elapsedTime: 0,
          ));
      _trimIfNeeded();
    }

    notifyListeners();
  }

  void addError(DioException dioError) {
    final model = _findByRequestOptions(dioError.requestOptions);

    if (model != null) {
      model.dioError = dioError;
      // dioError.response 4xx/5xx-də doludur — onu da saxla
      model.response ??= dioError.response;
      _markCompleted(model);
    } else {
      _requests.insert(
          0,
          DebugModel(
            id: _counter++,
            requestOptions: dioError.requestOptions,
            requestStartTime: DateTime.now(),
            dioError: dioError,
            response: dioError.response,
            requestEndTime: DateTime.now(),
            elapsedTime: 0,
          ));
      _trimIfNeeded();
    }

    notifyListeners();
  }

  void clear() {
    _requests.clear();
    _counter = 0;
    notifyListeners();
  }

  // ============ INTERNAL ============

  /// RequestOptions reference-i ilə tap — URI yox.
  /// Dio eyni instance-ı request → response zənciri boyu daşıyır.
  DebugModel? _findByRequestOptions(RequestOptions options) {
    for (final r in _requests) {
      if (identical(r.requestOptions, options)) return r;
    }
    return null;
  }

  void _markCompleted(DebugModel model) {
    final now = DateTime.now();
    model.requestEndTime = now;
    model.elapsedTime = now.difference(model.requestStartTime).inMilliseconds;
  }

  void _trimIfNeeded() {
    if (_requests.length > _maxRequests) {
      _requests.removeRange(_maxRequests, _requests.length);
    }
  }
}
