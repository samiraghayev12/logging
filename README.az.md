# dio_debug_logger

[Dio](https://pub.dev/packages/dio) üçün tətbiqdaxili şəbəkə log aləti. Tətbiqə sürüklənən debug
düyməsi əlavə edir: sorğu siyahısı (axtarış, filtr), Request / Response / Error detalları,
statistika, retry və cURL / Postman / JSON kopyalama.

**Quraşdırma 2 sətirdir və hər ikisi release build-də avtomatik söndürülür.**

[🇬🇧 English](README.md)

## Quraşdırma

```bash
flutter pub add dio_debug_logger
```

## İnteqrasiya (2 sətir)

```dart
import 'package:dio_debug_logger/dio_debug_logger.dart';

// 1) Dio sorğularını yaz
final dio = Dio()..addDebugLogger();

// 2) Debug düyməsini göstər
MaterialApp(
  builder: DioDebugLogger.builder(),
  home: const HomePage(),
);
```

Bu qədər. 🐞 düyməsinə basın, loglar açılacaq.

- Hər iki sətir **release build-də** heç nə etmir (default `kDebugMode`), ona görə prod-a
  çıxmazdan əvvəl silməyə ehtiyac yoxdur.
- `navigatorKey` və ya `navigatorObservers` lazım deyil — Navigator avtomatik tapılır.

### Mövcud `builder` varsa

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

### Başqa mühitlərdə (məs. staging) açmaq

```dart
dio.addDebugLogger(enabled: isStaging);

MaterialApp(builder: DioDebugLogger.builder(enabled: isStaging));
```

## Konfiqurasiya

```dart
DioDebugLogger.builder(
  backgroundColor: Colors.indigo,
  foregroundColor: Colors.white,
  icon: Icons.bug_report_rounded,
  buttonSize: 56,
  showBadge: true,                       // sorğu / xəta sayı
  initialAlignment: Alignment.centerLeft,
  snapToEdge: true,                      // buraxdıqda kənara yapışsın
);

dio.addDebugLogger(
  printToConsole: kDebugMode,
  redactSensitiveHeaders: true,          // konsolda Authorization maskalanır
  maxConsoleBodyLength: 2000,
);

DioDebugLogger.configure(maxRequests: 500);          // yaddaş limiti (default 200)
DioDebugLogger.retryClientBuilder = () => myDio;     // "Retry" üçün öz Dio-nuz
```

## Proqramla açmaq

```dart
DioDebugLogger.open(context);
DioDebugLogger.close(context);
DioDebugLogger.isOpen;
```

## 0.1.x-dən keçid

Köhnə API işləyir, amma "deprecated"-dir:

| Köhnə | Yeni |
|---|---|
| `dio.interceptors.add(DebugLogging())` | `dio.addDebugLogger()` (köhnə forma da işləyir) |
| `NetworkLogger.overlayBuilder(...)` | `DioDebugLogger.builder(...)` |
| `NetworkLogger.open/close/...` | `DioDebugLogger.open/close/...` |
| `openDebugPage(context)` | `DioDebugLogger.open(context)` |

> Qeyd: `NetworkLogger.overlayBuilder()` default olaraq həmişə açıq idi,
> `DioDebugLogger.builder()` isə yalnız debug build-də açıqdır (`enabled` verilməsə).

Ətraflı sənəd: [README.md](README.md)
