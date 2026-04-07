import 'package:flutter/animation.dart';

class MotionTokens {
  const MotionTokens._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve standardCurve = Curves.easeInOutCubic;
}
