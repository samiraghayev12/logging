import 'package:dio/dio.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugStorage {
  static final DebugStorage _singleton = DebugStorage._internal();

  factory DebugStorage() => _singleton;

  DebugStorage._internal();

  List<DebugModel> requests = [];
  var _counter = 0;

  // Adds request and stores start time
  addRequest(RequestOptions requestOptions) {
    var debugModel = DebugModel(
      id: _counter,
      requestOptions: requestOptions,
      requestStartTime: DateTime.now(),
    );
    requests.insert(0, debugModel);
    _counter++;
  }

  addResponse(Response response) {
    var request = requests.firstWhere(
      (element) => element.requestOptions?.uri == response.requestOptions.uri,
      orElse: () => DebugModel(),
    );
    request.response = response;
    request.elapsedTime = DateTime.now().difference(request.requestStartTime!).inMilliseconds;
    request.requestTime = DateTime.now().toString();
  }

  // Adds error and calculates elapsed time
  addError(DioException dioError) {
    var request = requests.firstWhere(
      (element) => element.requestOptions?.uri == dioError.requestOptions.uri,
      orElse: () => DebugModel(),
    );
    request.dioError = dioError;
    request.elapsedTime = DateTime.now().difference(request.requestStartTime!).inMilliseconds;
  }
}
