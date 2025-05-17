import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';

class DebugTool {
  static final DebugTool _instance = DebugTool._internal();
  bool _isInjected = false;
  bool _isOpened = false;

  factory DebugTool() => _instance;
  DebugTool._internal();

  void start(BuildContext context, String apiKey) {
    if (_isInjected) return; // ✅ artıq əlavə olunubsa, yenidən etmə
    _isInjected = true;

    final overlayState = Overlay.of(context);
    if (overlayState == null) {
      debugPrint("❗ Overlay is null — skipping DebugTool injection.");
      return;
    }

    final overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () async {
          if (!_isOpened) {
            _isOpened = true;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DebugPage(),
              ),
            );
            _isOpened = false;
          }
        },
        child: const SizedBox.expand(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}
