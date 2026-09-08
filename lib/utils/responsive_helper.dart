import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Debug UI ölçülərini ekran ölçüsünə görə uyğunlaşdırır.
///
/// Köhnə API (`getFontSize`, `getPadding`, `getSpacing`, `getResponsiveSize`,
/// `getUIElementSize`) olduğu kimi qalıb — yalnız əmsallar konservativləşib.
/// Əvvəl planşetdə hər şey 3x böyüdülürdü və mətnlər qutulardan daşırdı.
class ResponsiveHelper {
  const ResponsiveHelper._();

  /// Dizayn baza genişliyi (telefon).
  static const double _baseWidth = 360;

  /// Sistem "font size" ayarı ilə birlikdə icazə verilən maksimum böyümə.
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

    // Planşet: az miqdarda böyüt. Əvvəlki 3.0 əmsalı overflow yaradırdı.
    if (shortestSide >= 900) return 1.25;
    if (shortestSide >= 600) return 1.12;

    // Telefon: genişlik nisbəti, dar cihazlarda kiçilməsin deyə clamp.
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

  /// İkon/AppBar kimi UI elementləri üçün daha az aqressiv böyütmə.
  static double getUIElementSize(BuildContext context, double baseSize) =>
      baseSize * math.min(_scaleFactor(context), 1.15);

  /// Geniş ekranlarda sətirlərin həddindən artıq uzanmasının qarşısını alır.
  static double contentMaxWidth(BuildContext context) {
    final width = _size(context).width;
    return width > 1000 ? 1000 : width;
  }

  /// Statistika kartlarının sütun sayı.
  static int gridColumns(BuildContext context) {
    final width = _size(context).width;
    if (width >= 900) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  /// Debug səhifələrini sistemin böyük "font size" ayarından qoruyur —
  /// əks halda mətnlər qutulardan daşır.
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

  /// Geniş ekranda məzmunu ortalayır və maksimum genişliklə məhdudlaşdırır.
  static Widget constrain(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
