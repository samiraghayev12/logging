# dio_debug_logger

[![pub package](https://img.shields.io/pub/v/dio_debug_logger.svg)](https://pub.dev/packages/dio_debug_logger)

An in-app network inspector for [Dio](https://pub.dev/packages/dio). Adds a draggable debug
button to your app that opens a full log viewer: request list with search and filters,
request / response / error details, statistics, retry, and cURL / Postman / JSON export.

**Setup takes two lines, and both are automatically disabled in release builds.**

[🇦🇿 Azərbaycan dilində](README.az.md)

| Feature | |
|---|---|
| Draggable floating button with request/error badge | ✅ |
| Log list with search and status filter | ✅ |
| Request / Response / Error details with JSON tree view | ✅ |
| Statistics (success rate, slowest/fastest, by method) | ✅ |
| Copy as cURL / Postman / JSON / readable summary | ✅ |
| Retry a request | ✅ |
| Sensitive header masking (`Authorization`, `Cookie`, …) | ✅ |
| Responsive (phone → tablet, large fonts) | ✅ |

---

## Installation

```bash
flutter pub add dio_debug_logger
```

## Setup (2 lines)

```dart
import 'package:dio_debug_logger/dio_debug_logger.dart';

// 1) Record the requests of your Dio instance
final dio = Dio()..addDebugLogger();

// 2) Show the debug button
MaterialApp(
  builder: DioDebugLogger.builder(),
  home: const HomePage(),
);
```

That's it. Tap the 🐞 button to open the logs.

- Both lines do nothing in **release builds** (`kDebugMode` is the default), so you don't need
  to remove them before shipping.
- No `navigatorKey` or `navigatorObservers` needed — the navigator is found automatically.

### Already have a `builder`?

Pass it in — the debug button is placed on top of it:

```dart
MaterialApp(
  builder: DioDebugLogger.builder(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: child!,
    ),
  ),
);
```

### Enable it in other environments

Pass `enabled` to both lines, for example to show it in a staging build:

```dart
dio.addDebugLogger(enabled: isStaging);

MaterialApp(builder: DioDebugLogger.builder(enabled: isStaging));
```

---

## Configuration

```dart
DioDebugLogger.builder(
  enabled: kDebugMode,                   // default
  backgroundColor: Colors.indigo,
  foregroundColor: Colors.white,
  icon: Icons.bug_report_rounded,
  buttonSize: 56,
  showBadge: true,                       // request / error count
  initialAlignment: Alignment.centerLeft,
  snapToEdge: true,                      // snap to the nearest edge when released
);

dio.addDebugLogger(
  enabled: kDebugMode,                   // default
  printToConsole: kDebugMode,            // default
  redactSensitiveHeaders: true,          // mask Authorization etc. in the console
  maxConsoleBodyLength: 2000,
);

// How many requests are kept in memory (default 200)
DioDebugLogger.configure(maxRequests: 500);

// Use your own Dio for the "Retry" button (certificate pinning, base options, ...)
DioDebugLogger.retryClientBuilder = () => myDio;
```

---

## Opening the logs from code

```dart
DioDebugLogger.open(context);
DioDebugLogger.close(context);
DioDebugLogger.isOpen;           // bool
DioDebugLogger.isOpenNotifier;   // ValueListenable<bool>
```

---

## Accessing the logs directly

```dart
final storage = DioDebugLogger.storage;   // singleton ChangeNotifier

storage.count;
storage.errorCount;
storage.successCount;
storage.pendingCount;
storage.averageElapsedMs;
storage.requests;                // List<DebugModel>, newest first

storage.setRecording(false);     // pause recording
storage.clear();
storage.deleteById(id);
storage.exportAll(redact: true); // List<Map<String, dynamic>>
```

---

## What's on the log page

- **Search** by URL, method or status code
- **Filter** — All / Success / Errors / Pending
- **Multi-select** — long press to select, delete in bulk
- **Swipe** to delete a single log
- **⋮ menu** — Analytics, Pause recording, Copy all as JSON, Clear all
- **Details** — Request / Response / Error tabs, JSON tree ↔ raw text, headers, size and duration
- **Copy** — cURL, Postman collection, JSON, readable summary, response body only
  (the **Hide tokens** switch masks `Authorization` / `Cookie`)
- **Retry** — resend the request and see the result in place

---

## Security notes

- Sensitive headers (`Authorization`, `Cookie`, `X-Api-Key`, …) are masked in console output,
  in copied text (when **Hide tokens** is on, the default) and in `exportAll()`.
- The UI shows headers in full — this is a developer tool. Keep it disabled in production
  (the default).

---

## Migrating from 0.1.x

The old API still works but is deprecated:

| Old | New |
|---|---|
| `dio.interceptors.add(DebugLogging())` | `dio.addDebugLogger()` (the old form is still fine) |
| `NetworkLogger.overlayBuilder(...)` | `DioDebugLogger.builder(...)` |
| `NetworkLogger.open/close/...` | `DioDebugLogger.open/close/...` |
| `openDebugPage(context)` | `DioDebugLogger.open(context)` |

> Note: `NetworkLogger.overlayBuilder()` was enabled by default; `DioDebugLogger.builder()`
> is only enabled in debug builds unless you pass `enabled`.

## License

[MIT](LICENSE)
