import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Adaptive {
  const Adaptive._();

  static bool isWebLike(BuildContext context) {
    return kIsWeb || MediaQuery.of(context).size.width >= 900;
  }

  static double maxBodyWidth(BuildContext context) {
    return isWebLike(context) ? 980 : double.infinity;
  }
}
