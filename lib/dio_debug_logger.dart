/// In-app network inspector for Dio.
///
/// ```dart
/// // 1) Dio
/// dio.addDebugLogger();
///
/// // 2) MaterialApp
/// MaterialApp(
///   builder: DioDebugLogger.builder(),
/// );
/// ```
library;

// Environments
export 'environment/debug_environment.dart';

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
