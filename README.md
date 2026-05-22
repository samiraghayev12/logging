# Logging Service - Flutter Network Debug Tool

A comprehensive Flutter plugin for intercepting, logging, and visualizing HTTP network requests using **Dio**. This service provides a floating debug button with an interactive UI to inspect network calls, response times, headers, and error details in real-time.

## Features

- 🔍 **Network Request Interception** - Automatically captures all HTTP requests/responses made with Dio
- 📊 **Performance Metrics** - View request duration, status codes, and elapsed time
- 🎨 **Beautiful UI** - Dark mode support with a modern Material Design interface
- 🐛 **Error Tracking** - Detailed error information including status codes and messages
- 🔗 **Request Details** - View full request/response headers, bodies, and URLs
- 📈 **Analytics** - Statistics page showing network performance overview
- 🎯 **Floating Button** - Easy-to-access debug panel that doesn't interfere with your app

## Installation

### Option 1: Local Path (Development)

Əgər kitabxana lokal fayllarında varsa:

```yaml
dependencies:
  logging_service:
    path: ../logging
```

Sonra run edin:
```bash
flutter pub get
```

### Option 2: Pub.dev (Published Package)

```yaml
dependencies:
  logging_service: ^0.0.3
```

Sonra run edin:
```bash
flutter pub get
```

## ⚡ Sürətli Başlama Yoxlama Siyahısı

Layihənizə kitabxanı əlavə etmək üçün bu addımları izləyin:

- [ ] **1. pubspec.yaml-ı Redaktə Edin** - `logging_service` əlavə edin
- [ ] **2. Paketləri Yükləyin** - `flutter pub get` çalıştırın
- [ ] **3. Dio-yu İnisiyalizə Edin** - `DebugLogging()` əlavə edin
- [ ] **4. DebugTool-u Başlatın** - `debugTool.start(context, '')` çağırın
- [ ] **5. Test Edin** - API sorğusu göndərən buton əlavə edin
- [ ] **6. Yoxlayın** - Sağ alt köşədəki kəpənək iconuna klikləyin

---

## Başqa Proyektə Əlavə Etmə (Step-by-Step)

### 1️⃣ Layihə Strukturunuzu Hazırlayın

Düzgün qovluq strukturu:
```
my_flutter_app/
├── lib/
├── pubspec.yaml
└── ../logging_service/  ← Bu layihə
```

### 2️⃣ pubspec.yaml-a Əlavə Edin

`my_flutter_app/pubspec.yaml` açın və `dependencies`-ə əlavə edin:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.8.0+1
  logging_service:
    path: ../logging
```

### 3️⃣ Paketləri Yükləyin

```bash
cd my_flutter_app
flutter pub get
```

### 4️⃣ main.dart Dosyasını Yazın

Aşağıdakı kodu istifadə edin:

```dart
import 'package:flutter/material.dart';
import 'package:logging_service/logging_service.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App with Logging',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Dio dio;
  late DebugTool debugTool;

  @override
  void initState() {
    super.initState();
    _initializeDio();
    _initializeDebugTool();
  }

  void _initializeDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    
    // ✅ DebugLogging əlavə edin - avtomatik sorğu loqlama
    dio.interceptors.add(DebugLogging());
  }

  void _initializeDebugTool() {
    debugTool = DebugTool();
    
    // Context hazır olduqdan sonra start edin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugTool.start(context, '');
    });
  }

  @override
  void dispose() {
    debugTool.dispose();
    super.dispose();
  }

  void _makeTestRequest() async {
    try {
      final response = await dio.get('/posts/1');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success: ${response.statusCode}')),
      );
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Logging Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Network Request Example',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _makeTestRequest,
              icon: const Icon(Icons.send),
              label: const Text('Make Request'),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '👉 Sağ altkötən Kəpənək iconuna klikləyin\n'
                'Network loqlarını görmək üçün',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5️⃣ Uygulamayı Çalıştırın

```bash
flutter run
```

---

## Quick Integration

### Step 1: Initialize Dio with Logging Interceptor

**Variant 1: Tək Import (Tövsiyə edilir)**
```dart
import 'package:logging_service/logging_service.dart';
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(DebugLogging()); // ✅ Avtomatik loqlama
```

**Variant 2: Spesifik Import**
```dart
import 'package:logging_service/service/debug_logging.dart';
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(DebugLogging());
```

### Step 2: Start the Debug Tool in Your App

Əsas app widget-ində yaxud ilk səhifədə:

```dart
import 'package:logging_service/logging_service.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize debug tool
    final debugTool = DebugTool();
    
    return MaterialApp(
      home: MyHomePage(debugTool: debugTool),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final DebugTool debugTool;
  
  const MyHomePage({required this.debugTool});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Start debug tool with context
    DebugTool().start(context, ''); // API key parameter (if needed)
  }

  @override
  void dispose() {
    DebugTool().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(child: Text('Your app content here')),
    );
  }
}
```

## En Yaxşı Praktikalar

### Provider/GetX ilə İstifadə

**Provider ilə:**
```dart
class ApiService {
  late Dio dio;
  
  ApiService() {
    dio = Dio();
    dio.interceptors.add(LoggingInterceptor());
  }
  
  Future<Response> getUser(int id) {
    return dio.get('/users/$id');
  }
}

// main.dart-da
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => DebugTool()),
      ],
      child: const MyApp(),
    ),
  );
}
```

**GetX ilə:**
```dart
class ApiController extends GetxController {
  late Dio dio;
  
  @override
  void onInit() {
    super.onInit();
    dio = Dio();
    dio.interceptors.add(LoggingInterceptor());
  }
  
  Future<Response> getUser(int id) {
    return dio.get('/users/$id');
  }
}

// main.dart-da
void main() {
  Get.put(ApiController());
  Get.put(DebugTool());
  runApp(const MyApp());
}
```

### Singleton Pattern (Recommended)

```dart
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: const Duration(seconds: 10),
      ),
    );
    dio.interceptors.add(LoggingInterceptor());
  }
  
  Future<Response> get(String path) => dio.get(path);
  Future<Response> post(String path, dynamic data) => dio.post(path, data: data);
}

// İstifadə
ApiClient().get('/users');
```

### Environment-e Görə Aktivləşdirmə

```dart
const bool isDebugMode = !bool.fromEnvironment('dart.vm.product');

void _initializeDebugTool() {
  if (isDebugMode) {
    debugTool = DebugTool();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugTool.start(context, '');
    });
  }
}
```

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:logging_service/logging_service.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logging Service Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Dio dio;
  late DebugTool debugTool;

  @override
  void initState() {
    super.initState();
    
    // Initialize Dio with logging
    dio = Dio();
    dio.interceptors.add(LoggingInterceptor());
    
    // Initialize and start debug tool
    debugTool = DebugTool();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugTool.start(context, '');
    });
  }

  @override
  void dispose() {
    debugTool.dispose();
    super.dispose();
  }

  void _makeTestRequest() async {
    try {
      final response = await dio.get('https://jsonplaceholder.typicode.com/posts/1');
      print('Response: ${response.data}');
    } on DioException catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logging Service'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Press the floating button to view network logs'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _makeTestRequest,
              child: const Text('Make Test Request'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Usage Guide

### Viewing Network Logs

1. **Tap the floating debug button** (appears as a bug icon at the bottom-right)
2. **View all network requests** in the list with method, URL, status, and elapsed time
3. **Tap a request** to see detailed information:
   - Request headers and body
   - Response headers and body
   - Status codes and messages
   - Error details (if applicable)

### Analytics Page

- Access the analytics page by tapping the chart icon on the debug page
- View statistics about network performance:
  - Total requests
  - Success/error rates
  - Average response time
  - Most common endpoints

### Dark Mode Support

The UI automatically adapts to your app's theme (light/dark mode).

## API Reference

### DebugTool

```dart
class DebugTool {
  // Start the debug tool and show floating button
  void start(BuildContext context, String apiKey)
  
  // Close the debug tool and remove floating button
  void dispose()
}
```

### DebugStorage (Singleton)

```dart
class DebugStorage {
  // Get all captured requests
  List<DebugModel> requests
  
  // Add a new request (called by interceptor)
  void addRequest(RequestOptions requestOptions)
  
  // Update request with response
  void addResponse(Response response)
  
  // Update request with error
  void addError(DioException dioError)
}
```

### DebugModel

```dart
class DebugModel {
  // Request information
  String httpMethod           // GET, POST, PUT, DELETE, etc.
  String path                 // Request path
  String url                  // Full URL
  Map<String, dynamic> requestHeaders
  dynamic requestData
  
  // Response information
  String statusCode
  String statusMessage
  Map<String, dynamic> responseHeaders
  dynamic responseData
  
  // Timing
  DateTime? requestStartTime
  DateTime? requestEndTime
  int? elapsedTime            // Milliseconds
  String? requestTime         // Formatted timestamp
  
  // Error information
  bool hasError               // True if error occurred
  DioException? dioError
  String errorStatusCode
  String errorStatusMessage
  Map<String, dynamic> errorHeaders
}
```

## DebugLogging Interceptor Əsasları

`DebugLogging` sinfini istifadə edərək bütün Dio sorğularını avtomatik olaraq qeyd edin:

```dart
import 'package:logging_service/service/debug_logging.dart';
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(DebugLogging());
```

### Ne Edər

✅ **Bütün Sorğuları Tutun**
- Gidən istəkləri əngəlləyin
- Cavabları tutun
- Xətaları qeyd edin

✅ **Konsola Məlumat Yazdırın**
- 🐙 REQUEST - Sorğu başladığında
- 🦑 RESPONSE - Cavab alındığında  
- 🦀 ERROR - Xəta olduğunda

✅ **DebugStorage-da Saxlayın**
- Istəklər tarixçəsi
- Cavablar
- Xəta detalları
- Geçən vaxt ölçmələri

### Konsol Çıktısı Nümunəsi

```
🐙 REQUEST [ GET] => URL: https://jsonplaceholder.typicode.com/posts/1 => BODY: null => TIME: 2024-05-22 14:30:45.123456
🦑 RESPONSE [ 200] => DATA: {...} ] => TIME: 2024-05-22 14:30:46.456789 => ELAPSED TIME: 1333 ms
```

### Xəta Çıktısı

```
🦀 ERROR [ 404] => PATH: /posts/999 ] => TIME: 2024-05-22 14:31:10.123456 => ELAPSED TIME: 856 ms
```

## Xətaları Həll Etmə (Troubleshooting)

### ❌ Kəpənək Buttonu Görünmür

**Səbəb:** Context hazır deyil  
**Həll:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugTool.start(context, ''); // ✅ Widgetlər hazır olduqdan sonra
  });
}
```

### ❌ Sorğular Qeyd Edilmir

**Səbəb:** DebugLogging interceptor əlavə edilməyib  
**Həll:**
```dart
// ✅ Doğru
dio.interceptors.add(DebugLogging());

// ❌ Yanlış - bu etməyin
// dio.interceptors.add(Interceptor());
```

### ❌ "Null context" Xətası

**Səbəb:** `BuildContext` olmadan `start()` çağırıldı  
**Həll:**
```dart
// ❌ Yanlış
debugTool.start(context, ''); // initState-də context null ola bilər

// ✅ Doğru
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    debugTool.start(context, '');
  }
});
```

### ❌ İthalatlar Tapılmır

**Səbəb:** `flutter pub get` çalıştırılmadı  
**Həll:**
```bash
flutter pub get
flutter pub upgrade logging_service
```

### ❌ UI-da Məlumat Göstərilmir

**Səbəb:** Sorğular eyni Dio instansiyasından göndərilmir  
**Həll:**
```dart
// ✅ Singleton istifadə edin
class ApiClient {
  static final _instance = ApiClient._internal();
  late Dio dio;
  
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    dio = Dio();
    dio.interceptors.add(DebugLogging());
  }
}

// İstifadə
ApiClient().dio.get('/api/users');
```

### ❌ Yaşıl Buton Animasiya Edilmiyor

**Səbəb:** AnimationController düzgün işləməyir  
**Həll:** Flutter versiyasını yükləyin `>=3.3.0`
```bash
flutter upgrade
flutter pub get
```

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Dependencies

- `flutter: >=3.3.0`
- `dio: ^5.8.0+1`
- `flutter_screenutil: ^5.9.0` (for responsive UI)
- `json_view: ^0.4.2` (for JSON visualization)
- `intl: ^0.20.2` (for date formatting)

## Layihədə Necə İstifadə Etmək - Xülasə

### 📋 Minimum Tələbat

```
my_app/
├── lib/
│   └── main.dart          # DebugTool.start() burada
├── pubspec.yaml           # logging_service əlavə edin
└── ../logging_service/    # Bu repo
```

### 🔧 3 Dəqiqəlik Qurulum

**1️⃣ pubspec.yaml:**
```yaml
dependencies:
  logging_service:
    path: ../logging
```

**2️⃣ main.dart:**
```dart
import 'package:logging_service/logging_service.dart';

final dio = Dio();
dio.interceptors.add(DebugLogging());

class App extends StatefulWidget {
  @override
  void initState() {
    debugTool = DebugTool();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugTool.start(context, '');
    });
  }
}
```

**3️⃣ İstifadə:**
```dart
// API sorğusu göndərin
await dio.get('/api/users');

// Sağ alt kəpənəyə klikləyin 👇
// Bütün loqları görün
```

### 📊 Ne Görəcəksiniz

![Tasvir](https://via.placeholder.com/300x200?text=Debug+UI)

- ✅ HTTP metodlar (GET, POST, PUT, DELETE)
- ✅ URL və status kodları
- ✅ Geçən vaxt (ms)
- ✅ Cavab məlumatları
- ✅ Xəta detalları
- ✅ Analitika cədvəli

---

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.
