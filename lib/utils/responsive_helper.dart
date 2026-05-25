import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Telefon: 360-430px, Planşet: 600px+
    // Ratio hesabla
    final widthRatio = screenWidth / 360;

    return baseSize * widthRatio;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ratio = screenWidth / 360;

    // Minimum 0.8, maksimum 1.5 ratio
    final clampedRatio = ratio.clamp(0.8, 1.5);

    return baseSize * clampedRatio;
  }

  static double getPadding(BuildContext context, double basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ratio = screenWidth / 360;

    return basePadding * ratio.clamp(0.8, 1.5);
  }

  static double getSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ratio = screenWidth / 360;

    return baseSpacing * ratio.clamp(0.8, 1.5);
  }
}
