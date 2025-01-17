import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;
  start(
    BuildContext context,
    String apiKey,
  ) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
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

    Overlay.of(context).insert(overlayEntry);
  }
}
