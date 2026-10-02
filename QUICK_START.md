# ⚡ Quick Start

## 1. pubspec.yaml

```yaml
dependencies:
  dio_debug_logger: ^0.1.0
```

və ya terminaldan:

```bash
flutter pub add dio_debug_logger
```

```bash
flutter pub get
```

## 2. Dio

```dart
import 'package:dio_debug_logger/dio_debug_logger.dart';

final dio = Dio();
dio.interceptors.add(DebugLogging());
```

## 3. MaterialApp

```dart
MaterialApp(
  builder: NetworkLogger.overlayBuilder(enabled: kDebugMode),
  home: const HomePage(),
);
```

## 4. Nəticə

- Ekranda sürüklənən 🐞 düyməsi görünür (üstündə sorğu/xəta sayı)
- Klik → şəbəkə logları
- Loga klik → detallar (Request / Response / Error)
- ⋮ → Analytics, Pause, Copy all, Clear

Daha çox: [README.md](README.md)
