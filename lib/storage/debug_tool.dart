import 'package:flutter/material.dart';
import 'package:logging_service/service/shake_service.dart';

import '../presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;
  ShakeService? _shakeService;
  OverlayEntry? _overlayEntry;

  void start(BuildContext context, String apiKey) {
    _shakeService = ShakeService(
      onPhoneShake: () {
        if (!isOpened) {
          isOpened = true;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DebugPage(),
            ),
          ).then((_) {
            isOpened = false;
          });
        }
      },
    );
    _shakeService?.start();
  }

  void dispose() {
    _shakeService?.stop();
    _overlayEntry?.remove();
  }
}
