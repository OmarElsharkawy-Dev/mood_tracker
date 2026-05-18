import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 100;

  static const BorderRadius cardBR = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetBR =
      BorderRadius.vertical(top: Radius.circular(lg));
  static const BorderRadius pillBR = BorderRadius.all(Radius.circular(pill));
}
