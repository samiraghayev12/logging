# ⚡ Quick Start

## 1. Install

```bash
flutter pub add dio_debug_logger
```

## 2. Dio

```dart
import 'package:dio_debug_logger/dio_debug_logger.dart';

final dio = Dio()..addDebugLogger();
```

## 3. MaterialApp

```dart
MaterialApp(
  builder: DioDebugLogger.builder(),
  home: const HomePage(),
);
```

## 4. Result

- A draggable 🐞 button appears (with the request/error count)
- Tap → network logs
- Tap a log → details (Request / Response / Error)
- ⋮ → Analytics, Pause, Copy all, Clear

Both lines are disabled in release builds automatically.

More: [README.md](README.md)
