# dio_debug_logger demo

A demo app with a **fake REST API built into the app** (`lib/mock_api.dart`), so it works
offline and every request behaves the same way each time.

```bash
cd example
flutter run
```

Tap any request, or **Run all**, then tap the draggable 🐞 button to see the logs.

| Group | What it shows |
|---|---|
| Auth & tokens | login → access token, wrong password (401), Bearer header, expired token, refresh |
| CRUD | `GET` (with query params), `POST` (201), `PUT`, `PATCH`, `DELETE` (204) |
| Bodies & timing | filters, large response (100 items), multipart `FormData` upload, 3 s slow request |
| HTTP errors | 400 validation, 403, 404, 409, 422 problem+json, 429, 500, 503 plain text |
| Network failures | connection timeout, no internet (DNS), cancelled request |

The setup itself is just two lines — see `lib/main.dart`:

```dart
final dio = Dio()..addDebugLogger();               // 1
MaterialApp(builder: DioDebugLogger.builder());    // 2
```

> The debug button only shows in debug builds (`flutter run`). Profile/release builds hide it.
