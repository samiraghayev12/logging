# ⚡ Quick Start

## 1. pubspec.yaml

```yaml
dependencies:
  logging_service:
    git:
      url: https://github.com/samiraghayev12/logging.git
```

```bash
flutter pub get
```

## 2. Dio

```dart
import 'package:logging_service/logging_service.dart';

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
