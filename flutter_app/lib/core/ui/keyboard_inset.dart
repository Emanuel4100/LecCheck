import 'package:flutter/material.dart';

/// Wraps bottom-sheet content so IME insets use [sheetContext] (the overlay), not
/// the caller's context — otherwise [viewInsets.bottom] stays 0 on Android.
Widget wrapBottomSheetKeyboardPadding({
  required BuildContext sheetContext,
  EdgeInsets padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  required Widget child,
}) {
  final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
  return SafeArea(
    child: AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: padding.copyWith(bottom: padding.bottom + bottomInset),
      child: child,
    ),
  );
}
