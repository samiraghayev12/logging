# logging_service

Dio üçün şəbəkə log/debug aləti. Bütün UI kitabxananın içindədir — inteqrasiya etdiyin appda
**iki sətir** kifayət edir.

| | |
|---|---|
| Sürüklənən FAB (badge ilə) | ✅ kitabxanada |
| Log siyahısı + axtarış + filtr | ✅ |
| Detal (Request / Response / Error) | ✅ |
| Analitika | ✅ |
| cURL / Postman / JSON / Summary kopyalama | ✅ |
| Retry | ✅ |
| Responsive (telefon → planşet, böyük font) | ✅ |

---

## 1. Quraşdırma

```yaml
dependencies:
  logging_service:
    git:
      url: https://github.com/samiraghayev12/logging.git
```

## 2. İnteqrasiya (2 sətir)

```dart
// 1) Dio-ya interceptor
dio.interceptors.add(DebugLogging());

// 2) MaterialApp-a overlay
MaterialApp(
  builder: NetworkLogger.overlayBuilder(enabled: isDevEnvironment),
  home: ...,
);
```

Bu qədər. FAB, təkrar açılış qoruması, canlı yenilənmə, bağlama düyməsi — hamısı kitabxanadadır.
`navigatorKey` və ya `navigatorObservers` **məcburi deyil**: Navigator alt ağacda avtomatik tapılır.

### Mövcud `builder` varsa

```dart
builder: (context, child) {
  return MediaQuery(
    data: ...,
    child: DebugOverlay(
      enabled: isDevEnvironment,
      child: child ?? const SizedBox.shrink(),
    ),
  );
},
```

---

## 3. Konfiqurasiya

```dart
NetworkLogger.overlayBuilder(
  enabled: true,                       // prod-da false ver
  backgroundColor: UIColor.primary,
  foregroundColor: Colors.white,
  icon: Icons.bug_report_rounded,
  buttonSize: 56,
  showBadge: true,                     // sorğu/xəta sayı
  initialAlignment: Alignment.centerLeft,
  snapToEdge: true,                    // buraxdıqda kənara yapışsın
);
```

```dart
// Yaddaşda saxlanılan sorğu limiti (default 200)
NetworkLogger.configure(maxRequests: 500);

// "Retry" düyməsi öz Dio-nu istifadə etsin (cert pinning, baseOptions və s.)
NetworkLogger.retryClientBuilder = () => myDio;

// Interceptor parametrləri
dio.interceptors.add(DebugLogging(
  printToConsole: kDebugMode,
  redactSensitiveHeaders: true,   // konsolda Authorization maskalanır
  maxConsoleBodyLength: 2000,
));
```

---

## 4. Proqramla açmaq

```dart
NetworkLogger.open(context);    // və ya köhnə API: openDebugPage(context)
NetworkLogger.close(context);
NetworkLogger.isOpen;           // bool
NetworkLogger.isOpenNotifier;   // ValueListenable<bool>
```

---

## 5. Loglara birbaşa müraciət

```dart
final storage = DebugStorage();      // singleton, ChangeNotifier

storage.count;             // ümumi
storage.errorCount;        // xətalı
storage.successCount;
storage.pendingCount;
storage.averageElapsedMs;
storage.requests;          // List<DebugModel> (ən yenisi əvvəldə)

storage.setRecording(false);         // müvəqqəti dayandır
storage.clear();
storage.deleteById(id);
storage.exportAll(redact: true);     // List<Map<String, dynamic>>
```

`DebugStorage` `ChangeNotifier`-dir — UI-də `ListenableBuilder(listenable: DebugStorage(), ...)`
ilə istifadə edə bilərsən. **Kitabxananın öz səhifələri artıq özləri qulaq asır**, ona görə
`DebugPage`-i sarımağa ehtiyac yoxdur.

---

## 6. Debug səhifəsindəki imkanlar

- **Axtarış** — URL, metod, status kodu üzrə
- **Filtr** — All / Success / Errors / Pending
- **Çoxlu seçim** — uzun basıb seç, toplu sil
- **Sağa sürüşdür** — tək logu sil
- **⋮ menyusu** — Analytics, Pause recording, Copy all as JSON, Clear all
- **Detal** — Request / Response / Error tabları, JSON ağacı ↔ xam mətn keçidi,
  header-lər, ölçü və müddət göstəriciləri
- **Kopyala** — cURL, Postman collection, JSON, oxunaqlı xülasə, yalnız response body
  (`Hide tokens` açarı ilə `Authorization`/`cookie` maskalanır)
- **Retry** — sorğunu yenidən göndər, cavabı yerində gör

---

## 7. Responsive davranış

- Telefon: ekran genişliyinə görə `0.85–1.15` arası ölçüləndirmə
- Planşet: `1.12` (≥600dp) / `1.25` (≥900dp) — əvvəlki `3.0` əmsalı mətnləri daşırırdı
- Geniş ekranda məzmun mərkəzləşir və maksimum 1000dp genişlikdə saxlanılır
- Sistemin "font size" ayarı `1.25`-lə məhdudlaşdırılır ki, mətn qutulardan çıxmasın
- Bütün mətnlərdə `maxLines` + `ellipsis`, uzun dəyərlər `SelectableText` ilə sarılır

---

## Testlər

```bash
flutter test
```
