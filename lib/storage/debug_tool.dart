import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;

  start(
    BuildContext context,
  ) {
    final navigatorKey = GlobalKey<NavigatorState>();
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DebugPage()),
          );
        },
        child: const SizedBox.expand(),
      ),
    );

    navigatorKey.currentState?.overlay?.insert(overlayEntry);
    // Overlay'i ekliyoruz.
    Overlay.of(context).insert(overlayEntry);
  }
}
