import 'dart:ui';

import 'package:logging_service/service/shake_service.dart';

class DebugTool {
  ShakeService? shakeService;

  bool isOpened = false;

  start(VoidCallback onPhoneShake) {
    shakeService = ShakeService(
      onPhoneShake: () async {
        if (!isOpened) {
          isOpened = true;
          onPhoneShake();
          // await Navigation.push(RouteName.debugPage);
          isOpened = false;
        }
      },
    );

    shakeService?.start();
  }

  stop() {
    shakeService?.stop();
  }
}
