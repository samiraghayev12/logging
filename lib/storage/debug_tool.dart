import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;

  void start() {
    final navigatorKey = GlobalKey<NavigatorState>();

    final overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () async {
          if (!isOpened) {
            isOpened = true;
            navigatorKey.currentState
                ?.push(
              MaterialPageRoute(
                builder: (_) => const DebugPage(),
              ),
            )
                .then((_) {
              isOpened = false;
            });
          }
        },
        child: const SizedBox.expand(),
      ),
    );

    final overlay = navigatorKey.currentContext != null ? Overlay.of(navigatorKey.currentContext!, rootOverlay: true) : null;

    overlay?.insert(overlayEntry);
  }
}
