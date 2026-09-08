import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../presentation/overlay/debug_overlay.dart';
import '../presentation/page/debug_page.dart';
import '../storage/debug_storage.dart';
import 'debug_logging.dart';

/// Debug route-larını izləyir: təkrar push-un qarşısını alır və
/// `NetworkLogger`-ə `NavigatorState` verir.
class DebugNavigatorObserver extends NavigatorObserver {
  DebugNavigatorObserver();

  int _activeRoutes = 0;

  bool get hasActiveRoute => _activeRoutes > 0;

  bool _isDebugRoute(Route<dynamic>? route) =>
      route?.settings.name == NetworkLogger.routeName;

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

/// Kitabxananın ümumi giriş nöqtəsi.
///
/// Appda görülməli iş minimumdur:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [NetworkLogger.observer],
///   builder: NetworkLogger.overlayBuilder(enabled: isDev),
/// );
/// // və Dio üçün:
/// dio.interceptors.add(DebugLogging());
/// ```
class NetworkLogger {
  const NetworkLogger._();

  /// Debug səhifəsinin route adı.
  static const String routeName = '/logging_service/network-logs';

  /// `MaterialApp.navigatorObservers` siyahısına əlavə edilir.
  static final DebugNavigatorObserver observer = DebugNavigatorObserver();

  /// Observer istifadə edilmirsə alternativ olaraq təyin edilə bilər.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Debug səhifəsi açıqdırmı — FAB özünü gizlətmək üçün buna baxır.
  static final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  static bool get isOpen => isOpenNotifier.value;

  static DebugStorage get storage => DebugStorage();

  /// "Retry" düyməsi üçün Dio yaradır. Təyin edilməsə sadə `Dio()` istifadə olunur.
  ///
  /// Sertifikat pinning və ya xüsusi `BaseOptions` lazımdırsa appda bir dəfə:
  /// ```dart
  /// NetworkLogger.retryClientBuilder = () => myDio;
  /// ```
  static Dio Function()? retryClientBuilder;

  static Dio createRetryClient() => retryClientBuilder?.call() ?? Dio();

  /// Dio interceptor-u — `DebugLogging()` ilə eynidir.
  static Interceptor interceptor({
    bool? printToConsole,
    bool redactSensitiveHeaders = true,
  }) =>
      DebugLogging(
        printToConsole: printToConsole ?? kDebugMode,
        redactSensitiveHeaders: redactSensitiveHeaders,
      );

  /// Yaddaş limitini dəyişir.
  static void configure({int? maxRequests}) =>
      storage.configure(maxRequests: maxRequests);

  static NavigatorState? _resolveNavigator([BuildContext? context]) {
    final fromKey = navigatorKey?.currentState;
    if (fromKey != null) return fromKey;

    final fromObserver = observer.navigator;
    if (fromObserver != null) return fromObserver;

    if (context == null) return null;

    // Adi hal: overlay hansısa səhifənin içindədir.
    final fromAncestor = Navigator.maybeOf(context, rootNavigator: true);
    if (fromAncestor != null) return fromAncestor;

    // `MaterialApp.builder` halı: Navigator bu context-dən AŞAĞIDA olur,
    // ona görə alt ağacda axtarılır. Bu sayədə appda `navigatorObservers`
    // və ya `navigatorKey` təyin etmək məcburi deyil.
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

  /// Şəbəkə loglarını açır. Artıq açıqdırsa heç nə etmir.
  static Future<void> open([BuildContext? context]) async {
    if (isOpenNotifier.value || observer.hasActiveRoute) return;

    final navigator = _resolveNavigator(context);
    if (navigator == null) {
      assert(() {
        debugPrint(
          'NetworkLogger: Navigator tapılmadı. `MaterialApp.navigatorObservers`-ə '
          '`NetworkLogger.observer` əlavə edin və ya `NetworkLogger.navigatorKey` təyin edin.',
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

  /// Açıq olan bütün debug route-larını bağlayır.
  static void close([BuildContext? context]) {
    final navigator = _resolveNavigator(context);
    if (navigator == null) return;
    navigator.popUntil(
      (route) => route.isFirst || route.settings.name != routeName,
    );
  }

  /// `MaterialApp.builder`-ə birbaşa verilə bilən builder.
  ///
  /// ```dart
  /// MaterialApp(builder: NetworkLogger.overlayBuilder(enabled: isDev));
  /// ```
  static TransitionBuilder overlayBuilder({
    bool enabled = true,
    Color? backgroundColor,
    Color? foregroundColor,
    IconData icon = Icons.bug_report_rounded,
    double buttonSize = 56,
    bool showBadge = true,
    Alignment initialAlignment = Alignment.centerLeft,
    bool snapToEdge = true,
  }) {
    return (BuildContext context, Widget? child) => DebugOverlay(
          enabled: enabled,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          icon: icon,
          buttonSize: buttonSize,
          showBadge: showBadge,
          initialAlignment: initialAlignment,
          snapToEdge: snapToEdge,
          child: child ?? const SizedBox.shrink(),
        );
  }
}
