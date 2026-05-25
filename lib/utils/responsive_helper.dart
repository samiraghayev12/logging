import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool _isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600;
  }

  static double _getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isTablet(context)) {
      // Planşet: 2x büyütme
      return 3.0;
    } else {
      // Telefon: width ratiosu
      final ratio = screenWidth / 360;
      return ratio.clamp(0.85, 1.2);
    }
  }

  static double getResponsiveSize(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  static double getFontSize(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  static double getPadding(BuildContext context, double basePadding) {
    return basePadding * _getScaleFactor(context);
  }

  static double getSpacing(BuildContext context, double baseSpacing) {
    return baseSpacing * _getScaleFactor(context);
  }
}
