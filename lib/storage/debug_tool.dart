import 'package:flutter/material.dart';
import 'package:logging_service/presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;
  OverlayEntry? _overlayEntry;

  // Başlangıç metodu
  void start(BuildContext context) {
    if (_overlayEntry != null) return; // Eğer zaten başlatılmışsa tekrarlama

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onLongPress: () {
          _openDebugPage(context);
        },
        child: const SizedBox.expand(),
      ),
    );

    _insertOverlay(context);
  }

  // Overlay'i eklemek için metot
  void _insertOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);
    isOpened = true;
  }

  // Debug sayfasını açma
  void _openDebugPage(BuildContext context) {
    if (isOpened) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DebugPage()),
      );
    }
  }

  // Overlay'i kaldırma
  void removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      isOpened = false;
    }
  }
}
