## 0.3.0

### Environment switching

- Switch the backend (dev / staging / prod…) at runtime from the log page:
  `dio.addDebugLogger(environments: [DebugEnvironment('Dev', baseUrl: ...), ...])`.
- The selected environment is shown under the page title and as a badge on the floating
  button, and is remembered between app starts (`shared_preferences`).
- Only requests to one of the listed base URLs are rewritten; other hosts are left alone.
  Several Dio instances with the same environment names switch together.
- `DioDebugLogger.setEnvironments([...])` for Dio instances created lazily.
- `DioDebugLogger.environment`, `setEnvironment()` and `onEnvironmentChanged`.
- Release builds are unaffected: the logger (and the rewriting) is not added.
- Demo app: switch between Dev / Staging / Prod.

## 0.2.1

- New demo app in `example/` with a built-in fake API: GET / POST / PUT / PATCH / DELETE,
  auth tokens, FormData upload, slow and large responses, HTTP errors (400–503), timeouts,
  connection errors and cancelled requests.
- Animated demo on the pub.dev page and in the README.

## 0.2.0

### Simpler setup

- New `dio.addDebugLogger()` extension — adds the interceptor once (repeated calls are ignored).
- New `DioDebugLogger` class — the single entry point, named after the package.
  `DioDebugLogger.builder()` replaces `NetworkLogger.overlayBuilder()`.
- `DioDebugLogger.builder(builder: ...)` wraps an existing `MaterialApp.builder`.
- **Safe by default:** `addDebugLogger()` and `DioDebugLogger.builder()` are disabled in
  release builds (`enabled` defaults to `kDebugMode`).

### Deprecated

- `NetworkLogger` → use `DioDebugLogger`. It still works and keeps its old defaults
  (`overlayBuilder()` is enabled by default).
- `openDebugPage` / `closeDebugPage` → use `DioDebugLogger.open` / `DioDebugLogger.close`.

### Other

- Documentation, API docs, example app and remaining UI strings translated to English.
  Azerbaijani README: `README.az.md`.

## 0.1.0

### pub.dev

- Package renamed `logging_service` → `dio_debug_logger` (the old name is taken on pub.dev).
  Import: `package:dio_debug_logger/dio_debug_logger.dart`.
- Added MIT license, `repository` / `issue_tracker` / `topics` / `screenshots`.
- Unused native plugin templates are excluded from the package via `.pubignore`.

### Bug fixes

- `DebugPage` did not listen to `DebugStorage`, so new requests did not appear while it was open.
  All pages (list, details, analytics) now update live.
- The `Dismissible` key was `id-index`; when the list changed the key shifted and the wrong item
  was deleted. The key is now the `id` only, and deletion is by `id`.
- `DebugStorage.clear()` reset the counter, so a pending request could share an `id` with a new
  one (duplicate key → render error). The counter is no longer reset.
- Non-`String` header values (`content-length: 120`, `accept: [a, b]`) caused a type error in
  `Text(entry.value)`. All headers are normalized now.
- `hasError` sometimes counted pending requests as errors; a `Pending` state was added
  (no more `null ms` / wrong "Success" label).
- `CopyHelper.generateCurlCommand` did not escape single quotes (broken cURL), and `jsonEncode`
  threw on unencodable bodies. Both fixed; `FormData` is now written with `-F`.
- `RetryDialog` could call `setState` after `dispose`, resent the `content-length` header and
  did not show 4xx/5xx results.
- The copy dialog called `ScaffoldMessenger.of(context)` after `Navigator.pop`.
- `pubspec.yaml` referenced a missing `logging_service_web.dart` (broke web builds). The unused
  platform plugin definition and dependencies (`flutter_screenutil`, `intl`, `web`,
  `plugin_platform_interface`) were removed.

### Responsive

- Tablet scale factor was `3.0`, so text overflowed. Now `1.12` (≥600dp) / `1.25` (≥900dp),
  and `0.85–1.15` on phones.
- The system font size is capped at `1.25` on the debug pages.
- `maxLines` + `ellipsis` on all text; `SelectableText` for long values; fixed-width
  status/method labels with `FittedBox`; statistics cards use `Wrap`.
- Content is centered on wide screens (max 1000dp).

### New

- `DebugOverlay` / `NetworkLogger.overlayBuilder()` — draggable button with badge, edge snapping
  and double-open protection. No `navigatorKey` / `navigatorObservers` required.
- `NetworkLogger` — `open`, `close`, `isOpenNotifier`, `configure`, `retryClientBuilder`.
- Search (URL / method / status) and status filter (All / Success / Errors / Pending).
- ⋮ menu: Analytics, Pause/Resume recording, Copy all as JSON, Clear all.
- Detail header (status, duration, ↑/↓ size) and JSON tree ↔ raw text toggle.
- `FormData` support in the request view, cURL and JSON.
- Sensitive header masking (`Authorization`, `Cookie`, `X-Api-Key`, …) in the console, copy and
  export.
- `CopyHelper.generateSummary` (bug report text) and `generateResponseBody`.
- `DebugStorage`: `deleteById`, `deleteByIds`, `findById`, `setRecording`, `configure`,
  `exportAll`, `successCount`, `pendingCount`, `averageElapsedMs`.
- `DebugModel`: `status`, `isPending`, `isSuccess`, `requestSize`, `responseSize`,
  `underlyingError`, `toJson`, `matches`.
- Tests added (`flutter test`).

## 0.0.1

* Initial release.
