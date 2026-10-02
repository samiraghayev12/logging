# Integration Guide

## Minimum (new app)

```dart
// main.dart
MaterialApp(
  builder: DioDebugLogger.builder(),
  home: const HomePage(),
);

// api.dart
final dio = Dio()..addDebugLogger();
```

Nothing else is needed — the button, routing and live updates are handled by the package.
Both lines are disabled in release builds.

---

## With an existing `builder`

If `MediaQuery`, `ScreenUtil`, etc. are already in your `builder`, pass it to
`DioDebugLogger.builder`:

```dart
MaterialApp(
  builder: DioDebugLogger.builder(
    enabled: EnvironmentConfig.instance.environment.isDev,
    backgroundColor: UIColor.primary,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: ...),
      child: child!,
    ),
  ),
);
```

Or use the `DebugOverlay` widget directly as the outermost widget:

```dart
builder: (context, child) {
  return DebugOverlay(
    enabled: kDebugMode,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: ...),
      child: child ?? const SizedBox.shrink(),
    ),
  );
},
```

---

## Migrating from `logging_service` (git) / 0.1.x

1. Replace the git dependency with `dio_debug_logger: ^0.2.0`.
2. Update the import:

   ```dart
   // old
   import 'package:logging_service/logging_service.dart';
   // new
   import 'package:dio_debug_logger/dio_debug_logger.dart';
   ```

3. Optionally move to the new API (the old one still works but is deprecated):

| Old | New |
|---|---|
| `dio.interceptors.add(DebugLogging())` | `dio.addDebugLogger()` |
| `NetworkLogger.overlayBuilder(enabled: isDev)` | `DioDebugLogger.builder(enabled: isDev)` |
| `NetworkLogger.open(context)` / `openDebugPage(context)` | `DioDebugLogger.open(context)` |
| `NetworkLogger.retryClientBuilder` | `DioDebugLogger.retryClientBuilder` |

> `NetworkLogger.overlayBuilder()` is enabled by default; `DioDebugLogger.builder()` is
> enabled only in debug builds. Pass `enabled` explicitly if you need it elsewhere.

App code you can delete:

| Code in your app | Why |
|---|---|
| `ListenableBuilder(listenable: DebugStorage(), ...)` around `DebugPage` | `DebugPage` listens itself |
| Your own `DebugRouteObserver` | the package blocks double opening |
| Your own FAB / `DebugButtonOverlay` widget | built into `DioDebugLogger.builder()` |
| `PopScope` + `popUntil` wrappers | a single route is pushed, a plain `pop` is enough |

---

## Retry with your own Dio

For certificate pinning or custom `BaseOptions`:

```dart
void main() {
  DioDebugLogger.retryClientBuilder = () => ApiClient.instance.dio;
  runApp(const App());
}
```

---

## Sensitive data

- `Authorization`, `Cookie`, `X-Api-Key`, etc. are masked in console output
  (disable with `dio.addDebugLogger(redactSensitiveHeaders: false)`).
- The **Hide tokens** switch in the copy dialog is on by default.
- `DebugStorage().exportAll()` uses `redact: true` by default.
- The UI shows headers in full — it is a developer tool; keep it disabled in production.
