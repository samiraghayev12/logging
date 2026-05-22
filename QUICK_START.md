# ⚡ Quick Start - Copy & Paste

30 saniyəlik qurulum!

## 1️⃣ pubspec.yaml-ı Dəyişin

```yaml
dependencies:
  logging_service:
    path: ../logging
```

Run: `flutter pub get`

## 2️⃣ main.dart

```dart
import 'package:flutter/material.dart';
import 'package:logging_service/logging_service.dart';
import 'package:dio/dio.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Dio dio;
  late DebugTool debugTool;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    dio.interceptors.add(DebugLogging());
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => dio.get('https://jsonplaceholder.typicode.com/posts/1'),
          child: Text('Test Request'),
        ),
      ),
    );
  }
}
```

## 3️⃣ Çalıştırın

```bash
flutter run
```

## 4️⃣ Nəticə

- ✅ Sağ alt köşədə kəpənək görünəcək 🦋
- ✅ Düymə klikləyin → Sorqular göstərilər
- ✅ Sorgu klikləyin → Detallar göstərilər

---

**Seçim:** Daha çox məlumat üçün `README.md` oxuyun
