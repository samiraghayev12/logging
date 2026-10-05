import 'package:flutter/foundation.dart';

/// Tracks whether the logger was turned on in a release build on purpose and
/// warns loudly when it is.
class ReleaseGuard {
  const ReleaseGuard._();

  static bool _optedIn = false;
  static bool _warned = false;

  /// `true` in debug/profile builds, and in release builds only after an
  /// explicit `enabled: true`.
  static bool get allowed => !kReleaseMode || _optedIn;

  /// Call when a feature is enabled. In release builds this records the
  /// opt-in and prints a one-time warning.
  static void check(String feature) {
    if (!kReleaseMode) return;
    _optedIn = true;
    if (_warned) return;
    _warned = true;
    // ignore: avoid_print
    print(
      '⚠️ dio_debug_logger: $feature is enabled in a RELEASE build. Anyone '
      'holding this device can open the log and see network traffic. Never '
      'ship this to an app store.',
    );
  }
}
