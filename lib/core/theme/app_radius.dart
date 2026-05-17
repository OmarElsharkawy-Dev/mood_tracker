import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 9999;

  static const BorderRadius cardBR = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetBR = BorderRadius.vertical(top: Radius.circular(lg));
  static const BorderRadius pillBR = BorderRadius.all(Radius.circular(pill));
}
