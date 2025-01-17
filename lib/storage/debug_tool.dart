import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';
import 'package:logging_service/service/shake_service.dart';
import 'package:shake_flutter/shake_flutter.dart';

class DebugTool {
  ShakeService? shakeService;

  bool isOpened = false;

  start(
    BuildContext context,
    String apiKey,
  ) {
    shakeService = ShakeService(
      onPhoneShake: () async {
        if (!isOpened) {
          isOpened = true;
          await showCupertinoDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => CupertinoAlertDialog(
              title: const Text(
                "Xoş gəlmişsiniz!",
                style: TextStyle(
                  color: CupertinoColors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DebugPage(),
                    ),
                  ),
                  isDefaultAction: true,
                  child: const Text(
                    "Log",
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 500));
                    await Shake.start(apiKey);
                    await Shake.show();
                  },
                  isDefaultAction: true,
                  child: const Text(
                    "Feedback",
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
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
