# İnteqrasiya Bələdçisi

## Minimum (yeni app)

```dart
// main.dart
MaterialApp(
  builder: NetworkLogger.overlayBuilder(enabled: kDebugMode),
  home: const HomePage(),
);

// api.dart
dio.interceptors.add(DebugLogging());
```

Başqa heç nə lazım deyil — FAB, route idarəsi, canlı yenilənmə kitabxanadadır.

---

## Mövcud `builder` ilə birlikdə

`MediaQuery`, `ScreenUtil` və s. artıq `builder`-dədirsə, sadəcə ən xarici widget kimi
`DebugOverlay` əlavə et:

```dart
builder: (context, child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: ...),
    child: DebugOverlay(
      enabled: EnvironmentConfig.instance.environment.isDev,
      backgroundColor: UIColor.primary,
      child: child ?? const SizedBox.shrink(),
    ),
  );
},
```

---

## v0.0.x-dən v0.1.0-a keçid

Köhnə API işləməyə davam edir — heç nəyi dəyişmək **məcburi deyil**:

| Köhnə | Vəziyyət |
|---|---|
| `dio.interceptors.add(DebugLogging())` | dəyişməyib |
| `DebugStorage()` | dəyişməyib (yeni metodlar əlavə olunub) |
| `openDebugPage(context)` | dəyişməyib (indi təkrar açılışdan qorunur) |
| `const DebugPage()` | dəyişməyib |

Silinə bilən köhnə app kodu:

| Appdakı kod | Səbəb |
|---|---|
| `ListenableBuilder(listenable: DebugStorage(), ...)` sarğısı | `DebugPage` özü qulaq asır |
| Öz `DebugRouteObserver`-in | `NetworkLogger` təkrar açılışı özü bloklayır |
| Öz FAB / `DebugButtonOverlay` widget-in | `DebugOverlay` içindədir |
| `AppProvider.isDebugPageOpen`, `openDebugPage1()` | `NetworkLogger.isOpenNotifier` / `NetworkLogger.open()` |
| `PopScope` + `popUntil` sarğısı | tək route push olunur, adi `pop` kifayətdir |

---

## Prod-da gizlətmək

```dart
builder: NetworkLogger.overlayBuilder(
  enabled: EnvironmentConfig.instance.environment.isDev,
),
```

`enabled: false` olduqda overlay ümumiyyətlə qurulmur — `child` birbaşa qaytarılır.

---

## Retry üçün öz Dio-nu ver

Sertifikat pinning və ya xüsusi `BaseOptions` varsa:

```dart
void main() {
  NetworkLogger.retryClientBuilder = () => ApiClient.instance.dio;
  runApp(const App());
}
```

---

## Həssas məlumat

- Konsol logunda `Authorization`, `Cookie`, `X-Api-Key` və s. avtomatik maskalanır
  (`DebugLogging(redactSensitiveHeaders: false)` ilə söndürülə bilər).
- Kopyalama dialoqundakı **Hide tokens** açarı defolt olaraq açıqdır.
- `DebugStorage().exportAll()` defolt `redact: true` ilə işləyir.
- UI-də header-lər tam görünür — bu, developer alətidir; prod-da `enabled: false` ver.
