import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../environment/debug_environment.dart';
import '../presentation/overlay/debug_overlay.dart';
import '../presentation/page/debug_page.dart';
import '../storage/debug_model.dart';
import '../storage/debug_storage.dart';
import '../utils/redaction.dart';
import 'debug_logging.dart';
import 'release_guard.dart';

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
    if (_isDebugRoute(oldRoute)) {
      _activeRoutes = (_activeRoutes - 1).clamp(0, 999);
    }
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
  ///
  /// Pass [environments] to switch this Dio between backends from the log
  /// page. The Dio's own `baseUrl` should be one of them; requests to other
  /// hosts are never changed.
  ///
  /// ```dart
  /// dio.addDebugLogger(environments: [
  ///   DebugEnvironment('Dev', baseUrl: 'https://dev.api.example.com'),
  ///   DebugEnvironment('Prod', baseUrl: 'https://api.example.com'),
  /// ]);
  /// ```
  void addDebugLogger({
    bool enabled = kDebugMode,
    bool printToConsole = kDebugMode,
    bool redactSensitiveHeaders = true,
    int maxConsoleBodyLength = 2000,
    List<DebugEnvironment> environments = const [],
  }) {
    if (!enabled) return;
    if (interceptors.any((interceptor) => interceptor is DebugLogging)) return;
    assert(() {
      final base = options.baseUrl;
      String norm(String u) =>
          u.endsWith('/') ? u.substring(0, u.length - 1) : u;
      final list = environments.isNotEmpty
          ? environments
          : DebugEnvironments.instance.global;
      if (list.isNotEmpty &&
          base.isNotEmpty &&
          !list.any((e) => norm(e.baseUrl) == norm(base))) {
        debugPrint(
          'dio_debug_logger: this Dio\'s baseUrl "$base" is not one of its '
          'environments, so switching environments will not affect it.',
        );
      }
      return true;
    }());
    interceptors.add(
      DebugLogging(
        enabled: true,
        client: this,
        printToConsole: printToConsole,
        redactSensitiveHeaders: redactSensitiveHeaders,
        maxConsoleBodyLength: maxConsoleBodyLength,
        environments: environments,
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

  /// The Dio used to retry [model]: [retryClientBuilder] if set, otherwise
  /// the Dio that sent the request (keeps certificate pinning and options),
  /// otherwise a plain `Dio()`.
  static Dio createRetryClient([DebugModel? model]) {
    final custom = retryClientBuilder?.call();
    if (custom != null) return custom;
    final original = model?.requestOptions.extra[DebugLogging.clientKey];
    return original is Dio ? original : Dio();
  }

  /// Extra field names to mask, in addition to the built-in ones
  /// (passwords, tokens, keys, cookies, card data…):
  /// ```dart
  /// DioDebugLogger.sensitiveKeys.addAll({'national_id', 'iban'});
  /// ```
  static Set<String> get sensitiveKeys => Redaction.extraKeys;

  /// The Dio interceptor. Prefer `dio.addDebugLogger()`.
  static Interceptor interceptor({
    bool enabled = kDebugMode,
    bool printToConsole = kDebugMode,
    bool redactSensitiveHeaders = true,
    int maxConsoleBodyLength = 2000,
  }) => DebugLogging(
    enabled: enabled,
    printToConsole: printToConsole,
    redactSensitiveHeaders: redactSensitiveHeaders,
    maxConsoleBodyLength: maxConsoleBodyLength,
  );

  /// Environment registry (see `dio.addDebugLogger(environments: ...)`).
  static DebugEnvironments get environments => DebugEnvironments.instance;

  /// Sets environments for every Dio that doesn't pass its own list to
  /// `addDebugLogger`. Call it in `main()` so the switcher is available
  /// before the first request (useful when Dio is created lazily).
  ///
  /// Does nothing when [enabled] is `false` (release builds by default).
  static void setEnvironments(
    List<DebugEnvironment> environments, {
    bool enabled = kDebugMode,
  }) {
    if (!enabled) return;
    ReleaseGuard.check('Environment switching');
    DebugEnvironments.instance.setGlobal(environments);
  }

  /// The selected environment name, or `null` when the app's own base URLs
  /// are used.
  static String? get environment => DebugEnvironments.instance.selected;

  /// Switches the environment from code. `null` goes back to the app default.
  static Future<void> setEnvironment(String? name) =>
      DebugEnvironments.instance.select(name);

  /// Called after the environment is switched (`null` = app default).
  /// A good place to log the user out if sessions don't carry over.
  static set onEnvironmentChanged(void Function(String? name)? callback) =>
      DebugEnvironments.instance.onChanged = callback;

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
    if (!ReleaseGuard.allowed) return;
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
    if (enabled) ReleaseGuard.check('The debug button');
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

  static ValueNotifier<bool> get isOpenNotifier =>
      DioDebugLogger.isOpenNotifier;

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
  }) => DioDebugLogger.interceptor(
    printToConsole: printToConsole ?? kDebugMode,
    redactSensitiveHeaders: redactSensitiveHeaders,
  );

  static void configure({int? maxRequests}) =>
      DioDebugLogger.configure(maxRequests: maxRequests);

  static Future<void> open([BuildContext? context]) =>
      DioDebugLogger.open(context);

  static void close([BuildContext? context]) => DioDebugLogger.close(context);

  static TransitionBuilder overlayBuilder({
    bool enabled = kDebugMode,
    Color? backgroundColor,
    Color? foregroundColor,
    IconData icon = Icons.bug_report_rounded,
    double buttonSize = 56,
    bool showBadge = true,
    Alignment initialAlignment = Alignment.centerLeft,
    bool snapToEdge = true,
  }) => DioDebugLogger.builder(
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
