import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Adapts debug UI sizes to the screen size.
///
/// The API (`getFontSize`, `getPadding`, `getSpacing`, `getResponsiveSize`,
/// `getUIElementSize`) is unchanged — only the scale factors are more
/// conservative. Tablets used to scale everything 3x and text overflowed.
class ResponsiveHelper {
  const ResponsiveHelper._();

  /// Base design width (phone).
  static const double _baseWidth = 360;

  /// Maximum allowed scale, including the system font size setting.
  static const double _maxTextScale = 1.25;

  static Size _size(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isTablet(BuildContext context) => _size(context).shortestSide >= 600;

  static bool isLargeScreen(BuildContext context) => _size(context).shortestSide >= 900;

  static bool isLandscape(BuildContext context) {
    final size = _size(context);
    return size.width > size.height;
  }

  static double _scaleFactor(BuildContext context) {
    final size = _size(context);
    final shortestSide = size.shortestSide;

    // Tablet: scale up slightly. The old 3.0 factor caused overflow.
    if (shortestSide >= 900) return 1.25;
    if (shortestSide >= 600) return 1.12;

    // Phone: width ratio, clamped so narrow devices don't shrink too much.
    return (size.width / _baseWidth).clamp(0.85, 1.15);
  }

  static double getResponsiveSize(BuildContext context, double baseSize) =>
      baseSize * _scaleFactor(context);

  static double getFontSize(BuildContext context, double baseSize) =>
      baseSize * _scaleFactor(context);

  static double getPadding(BuildContext context, double basePadding) =>
      basePadding * _scaleFactor(context);

  static double getSpacing(BuildContext context, double baseSpacing) =>
      baseSpacing * _scaleFactor(context);

  /// Less aggressive scaling for UI elements such as icons and the AppBar.
  static double getUIElementSize(BuildContext context, double baseSize) =>
      baseSize * math.min(_scaleFactor(context), 1.15);

  /// Prevents overly long lines on wide screens.
  static double contentMaxWidth(BuildContext context) {
    final width = _size(context).width;
    return width > 1000 ? 1000 : width;
  }

  /// Number of columns for the statistics cards.
  static int gridColumns(BuildContext context) {
    final width = _size(context).width;
    if (width >= 900) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  /// Protects the debug pages from a large system font size setting —
  /// otherwise text overflows its boxes.
  static Widget clampTextScale(BuildContext context, Widget child) {
    final mediaQuery = MediaQuery.of(context);
    final currentScale = mediaQuery.textScaler.scale(14) / 14;
    if (currentScale <= _maxTextScale) return child;
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: const TextScaler.linear(_maxTextScale),
      ),
      child: child,
    );
  }

  /// Centers content on wide screens and limits it to a maximum width.
  static Widget constrain(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
