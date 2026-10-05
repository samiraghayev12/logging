# dio_debug_logger

[Dio](https://pub.dev/packages/dio) üçün tətbiqdaxili şəbəkə log aləti. Tətbiqə sürüklənən debug
düyməsi əlavə edir: sorğu siyahısı (axtarış, filtr), Request / Response / Error detalları,
statistika, retry və cURL / Postman / JSON kopyalama.

**Quraşdırma 2 sətirdir və hər ikisi release build-də avtomatik söndürülür.**

<p align="center">
  <img src="https://raw.githubusercontent.com/samiraghayev12/logging/master/doc/demo.webp" alt="dio_debug_logger demo" width="300">
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/samiraghayev12/logging/master/doc/environment.png" alt="Mühit dəyişmə" width="300">
</p>

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

## Mühit dəyişmək (dev / staging / prod)

Backend-i tətbiq işləyərkən log səhifəsindən dəyişin — yenidən build lazım deyil:

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
  ..addDebugLogger(environments: const [
    DebugEnvironment('Dev', baseUrl: 'https://dev.api.example.com', color: Colors.green),
    DebugEnvironment('Prod', baseUrl: 'https://api.example.com', color: Colors.red),
  ]);
```

**Network Logs** başlığının altındakı mühit adına toxunun və seçin. Yeni sorğular seçilmiş
ünvana gedir, düymədə nişan görünür (`DEV`), seçim tətbiq bağlanıb açılanda da qalır.
**Default** koddakı `baseUrl`-i istifadə edir.

- Release build-də logger əlavə olunmur — prod-a heç bir təsiri yoxdur.
- Yalnız siyahıdakı ünvanlara gedən sorğular dəyişir; CDN və başqa host-lar toxunulmaz qalır.
- Bir neçə Dio (API, auth) varsa, hər birinə eyni adlarla öz siyahısını verin — `Dev` seçəndə
  hamısı birlikdə dəyişir.
- Dio gec (lazy) yaradılırsa, `main()`-də `DioDebugLogger.setEnvironments([...])` çağırın.
- Mühit dəyişəndə logout üçün: `DioDebugLogger.onEnvironmentChanged = (name) => logout();`

## Təhlükəsizlik

- **Prod-da heç nə işləmir:** release build-də logger, düymə, mühit dəyişmə, `DebugLogging`,
  `DebugOverlay` və köhnə `NetworkLogger` API-si söndürülüb (`enabled: true` verməsəniz).
  Release-də açsanız, konsola xəbərdarlıq yazılır.
- **Gizli məlumatlar hər yerdə maskalanır:** parol, token, API açarı, cookie, OTP/PIN və kart
  məlumatları `••••••` kimi göstərilir — UI-də, konsolda, kopyalamada və export-da; header,
  body və URL query-də. UI-də 👁 ilə göstərmək olar (tətbiq yenidən açılanda sıfırlanır).
- Öz sahələrinizi əlavə edin: `DioDebugLogger.sensitiveKeys.addAll({'national_id'});`
- **Heç nə saxlanılmır və göndərilmir:** loglar yalnız yaddaşdadır, tətbiq bağlananda silinir;
  paket özü heç bir sorğu göndərmir.
- **Retry** sorğunu göndərən Dio ilə təkrarlayır — certificate pinning qorunur.

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
