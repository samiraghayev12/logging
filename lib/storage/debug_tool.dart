import 'package:flutter/material.dart';
import '../presentation/page/debug_page.dart';

class DebugTool {
  bool isOpened = false;
  OverlayEntry? _overlayEntry;
  BuildContext? _context;

  void start(BuildContext context, String apiKey) {
    _context = context;
    _showFloatingButton();
  }

  void _showFloatingButton() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: 20,
        bottom: 100,
        child: _DebugFloatingButton(
          onPressed: () => _openDebugPage(context),
        ),
      ),
    );

    Overlay.of(_context!).insert(_overlayEntry!);
  }

  void _openDebugPage(BuildContext context) {
    if (!isOpened) {
      isOpened = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DebugPage(),
        ),
      ).then((_) {
        isOpened = false;
      });
    }
  }

  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: 'Network Debug',
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.bug_report_rounded),
      ),
    );
  }
}

