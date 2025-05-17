void start(BuildContext context, String apiKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final overlay = Overlay.of(context);
    if (overlay == null) {
      debugPrint("⚠️ Overlay is null — couldn't insert overlay.");
      return;
    }

    final overlayEntry = OverlayEntry(
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

    overlay.insert(overlayEntry);
  });
}