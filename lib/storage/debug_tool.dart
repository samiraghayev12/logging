import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';
import 'package:logging_service/service/shake_service.dart';

class DebugTool {
  ShakeService? shakeService;

  bool isOpened = false;

  start(
    BuildContext context,
  ) {
    shakeService = ShakeService(
      onPhoneShake: () async {
        if (!isOpened) {
          isOpened = true;
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugPage()));
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
