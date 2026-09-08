import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'debug_model.dart';

/// Şəbəkə loglarının yaddaşdakı yeganə mənbəyi.
///
/// `DebugStorage()` həmişə eyni instansı qaytarır və `ChangeNotifier`-dir —
/// UI avtomatik yenilənir.
class DebugStorage extends ChangeNotifier {
  static final DebugStorage _singleton = DebugStorage._internal();

  factory DebugStorage() => _singleton;

  DebugStorage._internal();

  final List<DebugModel> _requests = [];
  int _counter = 0;

  /// Yaddaşda saxlanılan maksimum sorğu sayı.
  int _maxRequests = 200;

  /// Logların yığılmasını müvəqqəti dayandırır.
  bool _isRecording = true;

  int get maxRequests => _maxRequests;

  bool get isRecording => _isRecording;

  /// Read-only siyahı — UI bunu görür (ən yenisi əvvəldədir).
  List<DebugModel> get requests => List.unmodifiable(_requests);

  int get count => _requests.length;
  int get errorCount => _requests.where((r) => r.hasError).length;
  int get successCount => _requests.where((r) => r.isSuccess).length;
  int get pendingCount => _requests.where((r) => r.isPending).length;

  /// Yalnız tamamlanmış sorğuların orta müddəti (ms).
  int get averageElapsedMs {
    final completed = _requests.where((r) => r.elapsedTime != null).toList();
    if (completed.isEmpty) return 0;
    final total = completed.fold<int>(0, (sum, r) => sum + r.elapsedTime!);
    return (total / completed.length).round();
  }

  void configure({int? maxRequests}) {
    if (maxRequests != null && maxRequests > 0) {
      _maxRequests = maxRequests;
      _trimIfNeeded();
      notifyListeners();
    }
  }

  void setRecording(bool value) {
    if (_isRecording == value) return;
    _isRecording = value;
    notifyListeners();
  }

  DebugModel? findById(int id) {
    for (final request in _requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  void addRequest(RequestOptions requestOptions) {
    if (!_isRecording) return;
    _requests.insert(
      0,
      DebugModel(
        id: _nextId(),
        requestOptions: requestOptions,
        requestStartTime: DateTime.now(),
      ),
    );
    _trimIfNeeded();
    notifyListeners();
  }

  void addResponse(Response<dynamic> response) {
    if (!_isRecording) return;
    final model = _findByRequestOptions(response.requestOptions);

    if (model != null) {
      model.response = response;
      _markCompleted(model);
    } else {
      // Orphan — request log olunmayıb (interceptor sonradan əlavə olunub).
      _requests.insert(
        0,
        DebugModel(
          id: _nextId(),
          requestOptions: response.requestOptions,
          requestStartTime: DateTime.now(),
          response: response,
          requestEndTime: DateTime.now(),
          elapsedTime: 0,
        ),
      );
      _trimIfNeeded();
    }

    notifyListeners();
  }

  void addError(DioException dioError) {
    if (!_isRecording) return;
    final model = _findByRequestOptions(dioError.requestOptions);

    if (model != null) {
      model.dioError = dioError;
      // dioError.response 4xx/5xx-də doludur — onu da saxla.
      model.response ??= dioError.response;
      _markCompleted(model);
    } else {
      _requests.insert(
        0,
        DebugModel(
          id: _nextId(),
          requestOptions: dioError.requestOptions,
          requestStartTime: DateTime.now(),
          dioError: dioError,
          response: dioError.response,
          requestEndTime: DateTime.now(),
          elapsedTime: 0,
        ),
      );
      _trimIfNeeded();
    }

    notifyListeners();
  }

  void clear() {
    if (_requests.isEmpty) return;
    _requests.clear();
    // `_counter` sıfırlanmır: hələ cavabı gəlməmiş sorğular eyni id-ni alıb
    // siyahıda dublikat açar yarada bilər.
    notifyListeners();
  }

  /// İd-ə görə silmə — indekslər siyahı dəyişdikcə sürüşür.
  void deleteById(int id) {
    final removed = _requests.indexWhere((r) => r.id == id);
    if (removed == -1) return;
    _requests.removeAt(removed);
    notifyListeners();
  }

  void deleteByIds(Iterable<int> ids) {
    final target = ids.toSet();
    if (target.isEmpty) return;
    final before = _requests.length;
    _requests.removeWhere((r) => target.contains(r.id));
    if (_requests.length != before) notifyListeners();
  }

  /// İndeksə görə silmə (köhnə API — uyğunluq üçün saxlanılıb).
  void deleteAt(int index) {
    if (index >= 0 && index < _requests.length) {
      _requests.removeAt(index);
      notifyListeners();
    }
  }

  /// İndekslərə görə silmə (köhnə API — uyğunluq üçün saxlanılıb).
  void deleteMultiple(List<int> indexes) {
    final sorted = indexes.toSet().toList()..sort((a, b) => b.compareTo(a));
    var changed = false;
    for (final index in sorted) {
      if (index >= 0 && index < _requests.length) {
        _requests.removeAt(index);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Bütün logları JSON-a çevirir (export / paylaşma üçün).
  List<Map<String, dynamic>> exportAll({bool redact = true}) =>
      _requests.map((r) => r.toJson(redact: redact)).toList();

  // ============ INTERNAL ============

  int _nextId() => _counter++;

  /// RequestOptions reference-i ilə tap — URI yox.
  /// Dio eyni instansı request → response zənciri boyu daşıyır.
  DebugModel? _findByRequestOptions(RequestOptions options) {
    for (final r in _requests) {
      if (identical(r.requestOptions, options)) return r;
    }
    // Bəzi interceptor-lar `copyWith` edir — ehtiyat variant: eyni URI/metodlu
    // hələ tamamlanmamış ən son sorğunu tap.
    for (final r in _requests) {
      if (r.isPending &&
          r.requestOptions.method == options.method &&
          r.requestOptions.uri == options.uri) {
        return r;
      }
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
