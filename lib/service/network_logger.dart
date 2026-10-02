import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../presentation/overlay/debug_overlay.dart';
import '../presentation/page/debug_page.dart';
import '../storage/debug_storage.dart';
import 'debug_logging.dart';

/// Tracks debug routes: prevents pushing the log page twice and gives
/// [DioDebugLogger] access to a [NavigatorState].
class DebugNavigatorObserver extends NavigatorObserver {
  DebugNavigatorObserver();

  int _activeRoutes = 0;

  bool get hasActiveRoute => _activeRoutes > 0;

  bool _isDebugRoute(Route<dynamic>? route) =>
      route?.settings.name == DioDebugLogger.routeName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isDebugRoute(route)) _activeRoutes++;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isDebugRoute(route)) _activeRoutes = (_activeRoutes - 1).clamp(0, 999);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isDebugRoute(route)) _activeRoutes = (_activeRoutes - 1).clamp(0, 999);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isDebugRoute(oldRoute)) _activeRoutes = (_activeRoutes - 1).clamp(0, 999);
    if (_isDebugRoute(newRoute)) _activeRoutes++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Adds the network logger to a [Dio] instance.
extension DioDebugLoggerExtension on Dio {
  /// Records every request of this [Dio] instance in the debug logger.
  ///
  /// ```dart
  /// final dio = Dio()..addDebugLogger();
  /// ```
  ///
  /// Does nothing when [enabled] is `false` (defaults to `false` in release
  /// builds) or when the logger is already attached.
  void addDebugLogger({
    bool enabled = kDebugMode,
    bool printToConsole = kDebugMode,
    bool redactSensitiveHeaders = true,
    int maxConsoleBodyLength = 2000,
  }) {
    if (!enabled) return;
    if (interceptors.any((interceptor) => interceptor is DebugLogging)) return;
    interceptors.add(
      DebugLogging(
        printToConsole: printToConsole,
        redactSensitiveHeaders: redactSensitiveHeaders,
        maxConsoleBodyLength: maxConsoleBodyLength,
      ),
    );
  }
}

/// Main entry point of the package.
///
/// ```dart
/// // 1) Dio
/// dio.addDebugLogger();
///
/// // 2) MaterialApp
/// MaterialApp(
///   builder: DioDebugLogger.builder(),
/// );
/// ```
///
/// Both are disabled in release builds by default.
class DioDebugLogger {
  const DioDebugLogger._();

  /// Route name of the log page.
  static const String routeName = '/dio_debug_logger/network-logs';

  /// Optional: add to `MaterialApp.navigatorObservers`. Not required — the
  /// navigator is found automatically.
  static final DebugNavigatorObserver observer = DebugNavigatorObserver();

  /// Optional alternative to [observer] for locating the navigator.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Whether the log page is open. The floating button hides itself while it is.
  static final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  static bool get isOpen => isOpenNotifier.value;

  /// The in-memory log storage.
  static DebugStorage get storage => DebugStorage();

  /// Creates the [Dio] used by the "Retry" button. Defaults to a plain `Dio()`.
  ///
  /// Set it once if you need certificate pinning or custom `BaseOptions`:
  /// ```dart
  /// DioDebugLogger.retryClientBuilder = () => myDio;
  /// ```
  static Dio Function()? retryClientBuilder;

  static Dio createRetryClient() => retryClientBuilder?.call() ?? Dio();

  /// The Dio interceptor. Prefer `dio.addDebugLogger()`.
  static Interceptor interceptor({
    bool printToConsole = kDebugMode,
    bool redactSensitiveHeaders = true,
    int maxConsoleBodyLength = 2000,
  }) =>
      DebugLogging(
        printToConsole: printToConsole,
        redactSensitiveHeaders: redactSensitiveHeaders,
        maxConsoleBodyLength: maxConsoleBodyLength,
      );

  /// Changes how many requests are kept in memory (default 200).
  static void configure({int? maxRequests}) =>
      storage.configure(maxRequests: maxRequests);

  static NavigatorState? _resolveNavigator([BuildContext? context]) {
    final fromKey = navigatorKey?.currentState;
    if (fromKey != null) return fromKey;

    final fromObserver = observer.navigator;
    if (fromObserver != null) return fromObserver;

    if (context == null) return null;

    // Common case: the caller is inside a page.
    final fromAncestor = Navigator.maybeOf(context, rootNavigator: true);
    if (fromAncestor != null) return fromAncestor;

    // `MaterialApp.builder` case: the Navigator is BELOW this context, so the
    // subtree is searched. This is why `navigatorObservers` and
    // `navigatorKey` are optional.
    return _findDescendantNavigator(context);
  }

  static NavigatorState? _findDescendantNavigator(BuildContext context) {
    NavigatorState? found;

    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        found = element.state as NavigatorState;
        return;
      }
      element.visitChildElements(visit);
    }

    try {
      context.visitChildElements(visit);
    } catch (_) {
      return null;
    }
    return found;
  }

  /// Opens the log page. Does nothing if it is already open.
  static Future<void> open([BuildContext? context]) async {
    if (isOpenNotifier.value || observer.hasActiveRoute) return;

    final navigator = _resolveNavigator(context);
    if (navigator == null) {
      assert(() {
        debugPrint(
          'DioDebugLogger: Navigator not found. Pass a BuildContext, add '
          '`DioDebugLogger.observer` to `MaterialApp.navigatorObservers` or '
          'set `DioDebugLogger.navigatorKey`.',
        );
        return true;
      }());
      return;
    }

    isOpenNotifier.value = true;
    try {
      await navigator.push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: routeName),
          builder: (_) => const DebugPage(),
        ),
      );
    } finally {
      isOpenNotifier.value = false;
    }
  }

  /// Closes all open debug routes.
  static void close([BuildContext? context]) {
    final navigator = _resolveNavigator(context);
    if (navigator == null) return;
    navigator.popUntil(
      (route) => route.isFirst || route.settings.name != routeName,
    );
  }

  /// A builder for `MaterialApp.builder` that shows the draggable debug button.
  ///
  /// ```dart
  /// MaterialApp(builder: DioDebugLogger.builder());
  /// ```
  ///
  /// [enabled] defaults to `false` in release builds. If the app already has
  /// a `builder`, pass it as [builder]:
  /// ```dart
  /// MaterialApp(
  ///   builder: DioDebugLogger.builder(
  ///     builder: (context, child) => MediaQuery(..., child: child!),
  ///   ),
  /// );
  /// ```
  static TransitionBuilder builder({
    bool enabled = kDebugMode,
    TransitionBuilder? builder,
    Color? backgroundColor,
    Color? foregroundColor,
    IconData icon = Icons.bug_report_rounded,
    double buttonSize = 56,
    bool showBadge = true,
    Alignment initialAlignment = Alignment.centerLeft,
    bool snapToEdge = true,
  }) {
    return (BuildContext context, Widget? child) {
      final content = builder != null ? builder(context, child) : child;
      return DebugOverlay(
        enabled: enabled,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        icon: icon,
        buttonSize: buttonSize,
        showBadge: showBadge,
        initialAlignment: initialAlignment,
        snapToEdge: snapToEdge,
        child: content ?? const SizedBox.shrink(),
      );
    };
  }
}

/// Old name of [DioDebugLogger], kept for backward compatibility.
@Deprecated('Use DioDebugLogger instead. Will be removed in 1.0.0.')
class NetworkLogger {
  const NetworkLogger._();

  static const String routeName = DioDebugLogger.routeName;

  static DebugNavigatorObserver get observer => DioDebugLogger.observer;

  static GlobalKey<NavigatorState>? get navigatorKey =>
      DioDebugLogger.navigatorKey;
  static set navigatorKey(GlobalKey<NavigatorState>? value) =>
      DioDebugLogger.navigatorKey = value;

  static ValueNotifier<bool> get isOpenNotifier => DioDebugLogger.isOpenNotifier;

  static bool get isOpen => DioDebugLogger.isOpen;

  static DebugStorage get storage => DioDebugLogger.storage;

  static Dio Function()? get retryClientBuilder =>
      DioDebugLogger.retryClientBuilder;
  static set retryClientBuilder(Dio Function()? value) =>
      DioDebugLogger.retryClientBuilder = value;

  static Dio createRetryClient() => DioDebugLogger.createRetryClient();

  static Interceptor interceptor({
    bool? printToConsole,
    bool redactSensitiveHeaders = true,
  }) =>
      DioDebugLogger.interceptor(
        printToConsole: printToConsole ?? kDebugMode,
        redactSensitiveHeaders: redactSensitiveHeaders,
      );

  static void configure({int? maxRequests}) =>
      DioDebugLogger.configure(maxRequests: maxRequests);

  static Future<void> open([BuildContext? context]) =>
      DioDebugLogger.open(context);

  static void close([BuildContext? context]) => DioDebugLogger.close(context);

  /// Unlike [DioDebugLogger.builder], [enabled] defaults to `true` here.
  static TransitionBuilder overlayBuilder({
    bool enabled = true,
    Color? backgroundColor,
    Color? foregroundColor,
    IconData icon = Icons.bug_report_rounded,
    double buttonSize = 56,
    bool showBadge = true,
    Alignment initialAlignment = Alignment.centerLeft,
    bool snapToEdge = true,
  }) =>
      DioDebugLogger.builder(
        enabled: enabled,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        icon: icon,
        buttonSize: buttonSize,
        showBadge: showBadge,
        initialAlignment: initialAlignment,
        snapToEdge: snapToEdge,
      );
}
