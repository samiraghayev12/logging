import 'package:flutter/material.dart';

import '../../service/network_logger.dart';
import '../../storage/debug_storage.dart';

/// FAB mövqeyini rebuild-lər və səhifə keçidləri arasında saxlayır.
class _FabPosition {
  static Offset? offset;
}

/// Appın üzərinə sürüklənə bilən debug düyməsi əlavə edir.
///
/// `MaterialApp.builder` içində istifadə olunur — appda başqa heç nə lazım deyil:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [NetworkLogger.observer],
///   builder: (context, child) => DebugOverlay(
///     enabled: isDev,
///     child: child ?? const SizedBox.shrink(),
///   ),
/// );
/// ```
class DebugOverlay extends StatefulWidget {
  const DebugOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.icon = Icons.bug_report_rounded,
    this.buttonSize = 56,
    this.showBadge = true,
    this.initialAlignment = Alignment.centerLeft,
    this.snapToEdge = true,
    this.edgeMargin = 12,
  });

  final Widget child;

  /// `false` olduqda düymə tamamilə gizlənir (məs. prod mühiti).
  final bool enabled;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData icon;
  final double buttonSize;

  /// Sorğu/xəta sayını göstərən nişan.
  final bool showBadge;

  final Alignment initialAlignment;

  /// Buraxdıqda ən yaxın kənara yapışsın?
  final bool snapToEdge;

  final double edgeMargin;

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  Offset? _offset;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _offset = _FabPosition.offset;
  }

  Offset _defaultOffset(Size area) {
    final alignment = widget.initialAlignment;
    final maxX = (area.width - widget.buttonSize - widget.edgeMargin)
        .clamp(widget.edgeMargin, double.infinity);
    final maxY = (area.height - widget.buttonSize - widget.edgeMargin)
        .clamp(widget.edgeMargin, double.infinity);

    final x = widget.edgeMargin +
        ((alignment.x + 1) / 2) * (maxX - widget.edgeMargin);
    final y = widget.edgeMargin +
        ((alignment.y + 1) / 2) * (maxY - widget.edgeMargin);
    return Offset(x, y);
  }

  Offset _clamp(Offset value, Size area) {
    final maxX = (area.width - widget.buttonSize).clamp(0.0, double.infinity);
    final maxY = (area.height - widget.buttonSize).clamp(0.0, double.infinity);
    return Offset(
      value.dx.clamp(0.0, maxX),
      value.dy.clamp(0.0, maxY),
    );
  }

  /// Həmişə State-in öz context-i istifadə olunur: Navigator alt ağacda
  /// axtarıldığı üçün context `widget.child`-ın valideyni olmalıdır.
  void _openLogs() => NetworkLogger.open(context);

  void _store(Offset value) {
    _FabPosition.offset = value;
    _offset = value;
  }

  void _onPanUpdate(DragUpdateDetails details, Size area) {
    setState(() {
      _isDragging = true;
      _store(_clamp((_offset ?? _defaultOffset(area)) + details.delta, area));
    });
  }

  void _onPanEnd(Size area) {
    if (!widget.snapToEdge) {
      setState(() => _isDragging = false);
      return;
    }
    final current = _offset ?? _defaultOffset(area);
    final centerX = current.dx + widget.buttonSize / 2;
    final snappedX = centerX < area.width / 2
        ? widget.edgeMargin
        : area.width - widget.buttonSize - widget.edgeMargin;
    setState(() {
      _isDragging = false;
      _store(_clamp(Offset(snappedX, current.dy), area));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final area = Size(constraints.maxWidth, constraints.maxHeight);
                final position = _clamp(_offset ?? _defaultOffset(area), area);

                return ValueListenableBuilder<bool>(
                  valueListenable: NetworkLogger.isOpenNotifier,
                  builder: (context, isOpen, _) {
                    if (isOpen) return const SizedBox.shrink();
                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: _isDragging
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          left: position.dx,
                          top: position.dy,
                          width: widget.buttonSize,
                          height: widget.buttonSize,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) => _onPanUpdate(details, area),
                            onPanEnd: (_) => _onPanEnd(area),
                            onPanCancel: () => _onPanEnd(area),
                            child: _DebugFab(
                              icon: widget.icon,
                              size: widget.buttonSize,
                              backgroundColor: widget.backgroundColor,
                              foregroundColor: widget.foregroundColor,
                              showBadge: widget.showBadge,
                              onTap: _openLogs,
                              onLongPress: _openLogs,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

class _DebugFab extends StatelessWidget {
  const _DebugFab({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.onLongPress,
    required this.showBadge,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showBadge;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = backgroundColor ?? theme.colorScheme.primary;
    final foreground = foregroundColor ?? theme.colorScheme.onPrimary;

    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: foreground, size: size * 0.46),
              if (showBadge)
                Positioned(
                  top: size * 0.12,
                  right: size * 0.1,
                  child: const _DebugFabBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugFabBadge extends StatelessWidget {
  const _DebugFabBadge();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DebugStorage(),
      builder: (context, _) {
        final storage = DebugStorage();
        final errors = storage.errorCount;
        final total = storage.count;
        if (total == 0) return const SizedBox.shrink();

        final label = errors > 0
            ? (errors > 99 ? '99+' : '$errors')
            : (total > 99 ? '99+' : '$total');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          constraints: const BoxConstraints(minWidth: 16),
          decoration: BoxDecoration(
            color: errors > 0 ? Colors.red : Colors.blueGrey.shade700,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
