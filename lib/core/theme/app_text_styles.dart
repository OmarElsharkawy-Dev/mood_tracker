import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  // Display / headlines — Raleway Bold for screen titles + big stats numbers.
  static TextStyle get display => GoogleFonts.raleway(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get headline => GoogleFonts.raleway(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  // Section titles — Raleway SemiBold; sits between headline and UI labels.
  static TextStyle get title => GoogleFonts.raleway(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // Body / labels — Lora Regular for entry notes and descriptions.
  static TextStyle get body => GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // UI labels — Raleway SemiBold for buttons, chips, nav.
  static TextStyle get label => GoogleFonts.raleway(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.4,
      );

  // Captions / hints — Lora Regular; reduced opacity is applied at the call site.
  static TextStyle get caption => GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextTheme themeFor(Color onSurface) {
    final base = TextTheme(
      displayLarge: display,
      headlineSmall: headline,
      titleLarge: title,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: bodySmall,
      labelLarge: label,
      labelMedium: label,
      labelSmall: caption,
    );
    return base.apply(bodyColor: onSurface, displayColor: onSurface);
  }
}
