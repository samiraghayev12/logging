import 'package:flutter/material.dart';

import '../service/network_logger.dart';

/// Opens the log page.
@Deprecated('Use DioDebugLogger.open(context) instead. Will be removed in 1.0.0.')
void openDebugPage(BuildContext context) {
  DioDebugLogger.open(context);
}

/// Closes open debug pages.
@Deprecated('Use DioDebugLogger.close(context) instead. Will be removed in 1.0.0.')
void closeDebugPage(BuildContext context) {
  DioDebugLogger.close(context);
}
