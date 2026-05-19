import 'package:dio/dio.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugStorage {
  static final DebugStorage _singleton = DebugStorage._internal();

  factory DebugStorage() => _singleton;

  DebugStorage._internal();

  List<DebugModel> requests = [];
  var _counter = 0;

  // Adds request and stores start time
  void addRequest(RequestOptions requestOptions) {
    var debugModel = DebugModel(
      id: _counter,
      requestOptions: requestOptions,
      requestStartTime: DateTime.now(),
    );
    requests.insert(0, debugModel);
    _counter++;
  }

  void addResponse(Response response) {
    var request = requests.firstWhere(
      (element) => element.requestOptions?.uri == response.requestOptions.uri,
      orElse: () => DebugModel(),
    );
    request.response = response;
    request.elapsedTime =
        DateTime.now().difference(request.requestStartTime!).inMilliseconds;
    request.requestTime = DateTime.now().toString();
  }

  // Adds error and calculates elapsed time
  void addError(DioException dioError) {
    final requestUri = dioError.requestOptions.uri;

    // Find matching request by URI
    int index = requests.indexWhere(
      (element) => element.requestOptions?.uri == requestUri,
    );

    // If found, update existing request; otherwise create new one
    if (index != -1) {
      var request = requests[index];
      request.dioError = dioError;
      if (request.requestStartTime != null) {
        request.elapsedTime =
            DateTime.now().difference(request.requestStartTime!).inMilliseconds;
      }
      request.requestTime = DateTime.now().toString();
    } else {
      // Create new request entry if not found (shouldn't happen normally)
      var newRequest = DebugModel(
        id: _counter,
        requestOptions: dioError.requestOptions,
        dioError: dioError,
        requestStartTime: DateTime.now(),
        requestEndTime: DateTime.now(),
        requestTime: DateTime.now().toString(),
      );
      newRequest.elapsedTime = 0;
      requests.insert(0, newRequest);
      _counter++;
    }
  }
}
