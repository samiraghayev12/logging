import 'package:flutter/material.dart';

import '../service/network_logger.dart';

/// Şəbəkə loglarını açır (köhnə API — dəyişməyib).
///
/// Daxildə `NetworkLogger.open` çağırılır: təkrar açılışın qarşısı alınır.
void openDebugPage(BuildContext context) {
  NetworkLogger.open(context);
}

/// Açıq debug səhifələrini bağlayır.
void closeDebugPage(BuildContext context) {
  NetworkLogger.close(context);
}
