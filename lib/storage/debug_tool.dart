import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;

  void start(
    BuildContext context,
    String apiKey,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlayContext = Navigator.of(context).overlay?.context;

      if (overlayContext != null) {
        OverlayEntry overlayEntry = OverlayEntry(
          builder: (_) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () async {
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
            child: const SizedBox.expand(),
          ),
        );

        Overlay.of(overlayContext).insert(overlayEntry);
      } else {
        debugPrint("No Overlay found. Make sure MaterialApp or CupertinoApp is used.");
      }
    });
  }
}
