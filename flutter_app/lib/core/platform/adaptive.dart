import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Adaptive {
  const Adaptive._();

  static bool get isLinuxDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  static bool isWebLike(BuildContext context) {
    return kIsWeb || width(context) >= 900;
  }

  static bool isTablet(BuildContext context) {
    final w = width(context);
    final desktopThreshold = isLinuxDesktop ? 800.0 : 1100.0;
    return w >= 700 && w < desktopThreshold;
  }

  static bool isDesktop(BuildContext context) {
    final threshold = isLinuxDesktop ? 800.0 : 1100.0;
    return width(context) >= threshold;
  }

  static double maxBodyWidth(BuildContext context) {
    if (isDesktop(context)) return 1240;
    if (isTablet(context)) return 980;
    return double.infinity;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 16;
    return 12;
  }

  /// Phone-class layouts (portrait or landscape); use for dense grids and cards.
  static bool isCompactPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }
}
