import 'package:flutter/material.dart';

import '../../service/network_logger.dart';
import '../../environment/debug_environment.dart';
import '../../storage/debug_storage.dart';
import '../environment/environment_sheet.dart';

/// Keeps the button position across rebuilds and page transitions.
class _FabPosition {
  static Offset? offset;
}

/// Adds a draggable debug button on top of the app.
///
/// Usually created by `DioDebugLogger.builder()`. Use it directly only if
/// you need full control:
/// ```dart
/// MaterialApp(
///   builder: (context, child) => DebugOverlay(
///     enabled: kDebugMode,
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

  /// When `false`, the button is not built at all (e.g. in production).
  final bool enabled;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData icon;
  final double buttonSize;

  /// Shows a badge with the request/error count.
  final bool showBadge;

  final Alignment initialAlignment;

  /// Whether the button snaps to the nearest edge when released.
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

  /// Always uses the State's own context: the Navigator is searched in the
  /// subtree, so the context must be a parent of `widget.child`.
  void _openLogs() => DioDebugLogger.open(context);

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
                  valueListenable: DioDebugLogger.isOpenNotifier,
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
              Positioned(
                bottom: size * 0.08,
                child: const _EnvironmentBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the selected environment (e.g. "DEV") at the bottom of the button.
class _EnvironmentBadge extends StatelessWidget {
  const _EnvironmentBadge();

  @override
  Widget build(BuildContext context) {
    final registry = DebugEnvironments.instance;
    return ListenableBuilder(
      listenable: registry,
      builder: (context, _) {
        final name = registry.selected;
        if (name == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: registry.byName(name).first.color ?? Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            environmentBadge(name),
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
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
