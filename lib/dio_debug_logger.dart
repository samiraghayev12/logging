/// Dio əsaslı şəbəkə log/debug aləti.
///
/// Minimum inteqrasiya:
/// ```dart
/// // 1) Dio
/// dio.interceptors.add(DebugLogging());
///
/// // 2) MaterialApp
/// MaterialApp(
///   navigatorObservers: [NetworkLogger.observer],
///   builder: NetworkLogger.overlayBuilder(enabled: isDev),
/// );
/// ```
library;

// Storage
export 'storage/debug_tool.dart';
export 'storage/debug_storage.dart';
export 'storage/debug_model.dart';

// Service
export 'service/debug_logging.dart';
export 'service/network_logger.dart';

// Presentation
export 'presentation/page/debug_page.dart';
export 'presentation/stats/debug_stats.dart';
export 'presentation/detail/view/debug_detail.dart';
export 'presentation/overlay/debug_overlay.dart';

// Utils
export 'utils/copy_helper.dart';
export 'utils/log_formatter.dart';
export 'utils/responsive_helper.dart';
