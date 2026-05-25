import 'package:flutter/material.dart';
import '../presentation/page/debug_page.dart';

void openDebugPage(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const DebugPage()),
  );
}
