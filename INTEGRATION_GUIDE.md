# Integration Guide - Logging Service Plugin

Bu sənəd başqa Flutter layihəsinə `logging_service` əlavə etməyin ən sadə yolunu göstərir.

## 📁 Layihə Strukturu

```
home/
├── my_flutter_app/          ← Sizin layihəniz
│   ├── lib/
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── ...
│
└── logging_service/         ← Bu plugin
    ├── lib/
    ├── pubspec.yaml
    └── README.md
```

## 🚀 5 Addım

### Addım 1: pubspec.yaml-ı Dəyişin

`my_flutter_app/pubspec.yaml` açın:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.8.0+1                    # ← Əlavə edin (lazım varsa)
  logging_service:
    path: ../logging_service       # ← ÜÇ BÖLMƏ: Yolu doğru göstərin!
```

### Addım 2: Paketləri Yükləyin

```bash
cd my_flutter_app
flutter pub get
```

Əgər xəta alırsa:
```bash
flutter clean
flutter pub get
```

### Addım 3: main.dart-ı Yazın

Minimum misal:

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
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
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
    
    // 1️⃣ Dio yaradın və loqqlaşdırın
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.interceptors.add(DebugLogging());
    
    // 2️⃣ DebugTool başladın
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

  void _testRequest() async {
    try {
      final response = await dio.get('/posts/1');
      print('✅ Success: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Logging')),
      body: Center(
        child: ElevatedButton(
          onPressed: _testRequest,
          child: const Text('Make API Request'),
        ),
      ),
    );
  }
}
```

### Addım 4: Uygulamayı Çalıştırın

```bash
flutter run
```

### Addım 5: Test Edin

1. **"Make API Request" düyməsinə klikləyin**
2. **Sağ altkötən kəpənək iconuna klikləyin** 🦋
3. **Sorğunun detallarını görmək üçün tıklayın**

## 📱 Ekran Axışı

```
main() 
  ↓
MyApp (MaterialApp)
  ↓
HomePage (DebugTool.start() burada çalışır)
  ↓
┌─────────────────────────────┐
│ Floating Floating Button 🦋  │ (Sağ alt)
└─────────────────────────────┘
  ↓
DebugPage (Network Logs)
  ├── All Requests List
  ├── Request Details (Klikləyin)
  └── Analytics Page 📊
```

## 🔑 Əsas Konseptlər

| Komponent | Funksiyası |
|-----------|-----------|
| **Dio** | HTTP istəqləri göndərən kitabxana |
| **DebugLogging** | Dio-ya əlavə olunan interceptor - bütün sorğuları qeyd edir |
| **DebugStorage** | Sorguları saxlayan Singleton |
| **DebugTool** | Floating button göstərən və UI-yönetən sınıf |
| **DebugPage** | Loqları gösrən UI səhifəsi |

## 🎯 Bir Baxışda

```dart
// 1. Import edin
import 'package:logging_service/logging_service.dart';

// 2. Dio yaradın və DebugLogging əlavə edin
dio = Dio();
dio.interceptors.add(DebugLogging());

// 3. DebugTool başladın
debugTool = DebugTool();
debugTool.start(context, '');

// 4. İstifadə edin
await dio.get('/api/data');

// 5. Kəpənəyə klikləyin 🦋 → Loqları görün
```

## ⚠️ Ümumi Xətalar

| Xəta | Həll |
|------|------|
| "Package not found" | `flutter pub get` çalıştırın |
| "Null context" | `WidgetsBinding.instance.addPostFrameCallback()` istifadə edin |
| "No logs showing" | `DebugLogging()` əlavə etdiyinizə əmin olun |
| "Button doesn't appear" | `dispose()` çağırma unudmayın |

## 📚 Daha Çox

- Dəqiq API dəyişiklikləri üçün `../logging/README.md` oxuyun
- Kod nümunələri üçün `../logging/lib/` qovluğuna baxın
- Xəta həlli üçün README-nin "Troubleshooting" bölməsinə baxın

---

**Hazırlamış: Samir Aghayev**  
**Tarix: 2024-05-22**
