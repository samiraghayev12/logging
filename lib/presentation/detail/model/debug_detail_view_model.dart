import 'dart:async';

enum DetailButton { request, response }

class DebugDetailViewModel {
  final _buttonController = StreamController<DetailButton>.broadcast();

  Stream<DetailButton> get detailButtonStream => _buttonController.stream;

  choose(DetailButton detailButton) {
    _buttonController.sink.add(detailButton);
  }

  close() {
    _buttonController.close();
  }
}
