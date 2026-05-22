import 'package:flutter/material.dart';
import '../presentation/page/debug_page.dart';

class DebugTool {
  static final DebugTool _instance = DebugTool._internal();
  factory DebugTool() => _instance;
  DebugTool._internal();

  bool _isPageOpen = false;
  OverlayEntry? _overlayEntry;

  void start(BuildContext context, [String? apiKey]) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        right: 20,
        bottom: 100,
        child: _DebugFloatingButton(
          onPressed: () => _openDebugPage(overlayContext),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _openDebugPage(BuildContext context) {
    if (_isPageOpen) return;
    _isPageOpen = true;

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(builder: (_) => const DebugPage()),
        )
        .then((_) => _isPageOpen = false);
  }

  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isPageOpen = false;
  }
}

class _DebugFloatingButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _DebugFloatingButton({required this.onPressed});

  @override
  State<_DebugFloatingButton> createState() => _DebugFloatingButtonState();
}

class _DebugFloatingButtonState extends State<_DebugFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: 'Network Debug',
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.bug_report_rounded, color: Colors.white),
      ),
    );
  }
}
