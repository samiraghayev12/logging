# dio_debug_logger

[![pub package](https://img.shields.io/pub/v/dio_debug_logger.svg)](https://pub.dev/packages/dio_debug_logger)

An in-app network inspector for [Dio](https://pub.dev/packages/dio). Adds a draggable debug
button to your app that opens a full log viewer: request list with search and filters,
request / response / error details, statistics, retry, and cURL / Postman / JSON export.

**Setup takes two lines, and both are automatically disabled in release builds.**
**🔒 Safe by default** — see [Security & privacy](#security--privacy).

<p align="center">
  <img src="https://raw.githubusercontent.com/samiraghayev12/logging/master/doc/demo.webp" alt="dio_debug_logger demo" width="320">
</p>

[🇦🇿 Azərbaycan dilində](README.az.md)

| Feature | |
|---|---|
| Draggable floating button with request/error badge | ✅ |
| Log list with search and status filter | ✅ |
| Request / Response / Error details with JSON tree view | ✅ |
| Statistics (success rate, slowest/fastest, by method) | ✅ |
| Copy as cURL / Postman / JSON / readable summary | ✅ |
| Retry a request | ✅ |
| Passwords, tokens and keys masked everywhere (UI, console, copy, export) | ✅ |
| Responsive (phone → tablet, large fonts) | ✅ |
| Switch between backends (dev / staging / prod) at runtime | ✅ |

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

## Security & privacy

A network logger sees everything your app sends, so it is built to be safe by default.
Every point below is covered by tests.

**Nothing runs in production**

- `addDebugLogger()`, `DioDebugLogger.builder()`, `setEnvironments()`, the `DebugLogging`
  interceptor and the `DebugOverlay` widget are all **off in release builds** unless you pass
  `enabled: true` yourself. Off means: no recording, no button, no URL rewriting — requests pass
  through untouched.
- The deprecated `NetworkLogger` API follows the same rule.
- If you do enable it in a release build (e.g. an internal QA build), a warning is printed so it
  can't slip into a store build unnoticed, and `DioDebugLogger.open()` only works after such an
  explicit opt-in.

**Secrets are masked everywhere**

Passwords, tokens, API keys, cookies, OTP/PIN codes and card data are replaced with `••••••`:

| Where | Headers | Body fields | URL query |
|---|---|---|---|
| Log UI (tap 👁 on the detail page to reveal, resets on restart) | ✅ | ✅ | ✅ |
| Console output | ✅ | ✅ | ✅ |
| Copy as cURL / Postman / JSON / summary (**Hide secrets**, on by default) | ✅ | ✅ | ✅ |
| `Copy all as JSON` / `exportAll()` | ✅ | ✅ | ✅ |

Field names are matched in any style — `password`, `access_token`, `refreshToken`, `X-Api-Key`,
`client_secret`, `pin`, `cvv`… Nested JSON, JSON strings, form-encoded bodies and `FormData`
are all handled. Add your own fields:

```dart
DioDebugLogger.sensitiveKeys.addAll({'national_id', 'iban', 'diagnosis'});
```

**Nothing is stored or sent anywhere**

- Logs live **in memory only** (last 200 requests by default) and disappear when the app
  closes. Nothing is written to disk except the name of the selected environment.
- The package makes no network calls of its own and has no analytics.
- The environment switcher only offers the base URLs written in your code — there is no field
  to type an arbitrary address, and requests to other hosts are never changed.
- **Retry** resends with the same Dio that made the request, so certificate pinning and your
  interceptors still apply (or set `DioDebugLogger.retryClientBuilder`).

**Your part**

- Don't pass `enabled: true` to builds that go to app stores.
- If your API uses unusual names for secret or personal fields, add them to
  `DioDebugLogger.sensitiveKeys`.

---

## Switching environments

Switch the backend at runtime from the log page — no rebuild, no flavors. List your
environments when adding the logger:

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
  ..addDebugLogger(environments: const [
    DebugEnvironment('Dev', baseUrl: 'https://dev.api.example.com', color: Colors.green),
    DebugEnvironment('Staging', baseUrl: 'https://staging.api.example.com', color: Colors.orange),
    DebugEnvironment('Prod', baseUrl: 'https://api.example.com', color: Colors.red),
  ]);
```

Tap the environment under the **Network Logs** title to switch. New requests go to the selected
base URL, the button shows a badge (`DEV`, `STA`…), and the choice is remembered after restarts.
**Default** uses the base URL configured in your code.

- **Safe in production:** in release builds the logger isn't added, so nothing is rewritten.
- Only requests whose base URL is one of the listed ones are changed — requests to other hosts
  (CDNs, absolute URLs) are left alone. Your Dio's own `baseUrl` should be in the list.
- **Several Dio instances** (e.g. API and auth): give each its own list with the same names —
  selecting `Dev` switches all of them.
- **Dio created lazily?** Declare the environments in `main()` so the switcher is there before
  the first request. Every Dio without its own list uses them:

  ```dart
  DioDebugLogger.setEnvironments(const [
    DebugEnvironment('Dev', baseUrl: 'https://dev.api.example.com'),
    DebugEnvironment('Prod', baseUrl: 'https://api.example.com'),
  ]);
  ```

- Switching backends usually invalidates the session — react to it:

  ```dart
  DioDebugLogger.onEnvironmentChanged = (name) => authService.logout();
  DioDebugLogger.environment;               // selected name, or null for default
  await DioDebugLogger.setEnvironment('Dev'); // from code (null = default)
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
  (**Hide secrets**, on by default, masks passwords, tokens and keys)
- **Retry** — resend the request and see the result in place

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
