## 0.1.0

### Bug fix

- `DebugPage` `DebugStorage`-a qulaq asmırdı — səhifə açıq ikən yeni sorğular görünmürdü.
  Artıq bütün səhifələr (siyahı, detal, analitika) canlı yenilənir.
- `Dismissible` açarı `id-index` idi; siyahı dəyişəndə açar sürüşür və səhv element silinirdi.
  İndi açar yalnız `id`-dir və silmə də `id` üzrə gedir.
- `DebugStorage.clear()` sayğacı sıfırlayırdı → hələ cavabı gəlməmiş sorğu ilə eyni `id`
  yaranırdı (dublikat açar → render xətası). Sayğac artıq sıfırlanmır.
- Header dəyəri `String` olmayanda (`content-length: 120`, `accept: [a, b]`) `Text(entry.value)`
  runtime-da tip xətası atırdı. Bütün header-lər normallaşdırılır.
- `hasError` hələ cavabı gəlməmiş sorğunu bəzən xəta sayırdı; `Pending` vəziyyəti əlavə olundu
  (`null ms` / yanlış "Success" nişanı aradan qalxdı).
- `CopyHelper.generateCurlCommand` tək dırnaqları escape etmirdi — çıxan cURL sınırdı;
  `jsonEncode` kodlana bilməyən body-də exception atırdı. Hər ikisi düzəldildi, `FormData`
  artıq `-F` ilə yazılır.
- `RetryDialog` `dispose`-dan sonra `setState` çağıra bilirdi; `content-length` header-i
  yenidən göndərilirdi; 4xx/5xx nəticəsi görünmürdü.
- Kopyalama dialoqu `Navigator.pop`-dan sonra `ScaffoldMessenger.of(context)` çağırırdı.
- `pubspec.yaml` mövcud olmayan `logging_service_web.dart` faylına istinad edirdi (web build sınırdı).
  İstifadə olunmayan platform plugin təyinatı və dependency-lər (`flutter_screenutil`, `intl`,
  `web`, `plugin_platform_interface`) silindi.

### Responsive

- Planşetdə ölçü əmsalı `3.0` idi → mətnlər qutulardan daşırdı. İndi `1.12` (≥600dp) /
  `1.25` (≥900dp), telefonda `0.85–1.15`.
- Sistem "font size" ayarı debug səhifələrində `1.25`-lə məhdudlaşdırılır.
- Bütün mətnlərə `maxLines` + `ellipsis`; uzun dəyərlər üçün `SelectableText`;
  status/metod nişanları `FittedBox` + sabit genişlik; statistika kartları `Wrap` ilə.
- Geniş ekranda məzmun mərkəzləşir (maks. 1000dp).

### Yeni

- `DebugOverlay` / `NetworkLogger.overlayBuilder()` — sürüklənən FAB, badge, kənara yapışma,
  təkrar açılış qoruması. Appda `navigatorKey`/`navigatorObservers` tələb olunmur.
- `NetworkLogger` — `open`, `close`, `isOpenNotifier`, `configure`, `retryClientBuilder`.
- Log siyahısında axtarış (URL/metod/status) və status filtri (All/Success/Errors/Pending).
- ⋮ menyusu: Analytics, Pause/Resume recording, Copy all as JSON, Clear all.
- Detal səhifəsində xülasə başlığı (status, müddət, ↑/↓ ölçü) və JSON ağacı ↔ xam mətn keçidi.
- `FormData` artıq həm request, həm cURL, həm də JSON görünüşündə dəstəklənir.
- Həssas header maskalama (`Authorization`, `Cookie`, `X-Api-Key`, …) — konsol, kopyalama və export.
- `CopyHelper.generateSummary` (bug report üçün mətn) və `generateResponseBody`.
- `DebugStorage`: `deleteById`, `deleteByIds`, `findById`, `setRecording`, `configure`,
  `exportAll`, `successCount`, `pendingCount`, `averageElapsedMs`.
- `DebugModel`: `status`, `isPending`, `isSuccess`, `requestSize`, `responseSize`,
  `underlyingError`, `toJson`, `matches`.
- Dart testləri əlavə olundu (`flutter test`).

### Uyğunluq

Köhnə API tam işləyir: `DebugLogging()`, `DebugStorage()`, `openDebugPage(context)`,
`const DebugPage()`, `DebugDetail`, `DebugStats`, `CopyHelper`, `ResponsiveHelper`.

## 0.0.1

* İlk versiya.
