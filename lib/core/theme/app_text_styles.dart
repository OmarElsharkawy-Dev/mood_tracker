import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle get display => GoogleFonts.lora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get headline => GoogleFonts.lora(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get title => GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.raleway(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.raleway(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.4,
      );

  static TextStyle get caption => GoogleFonts.raleway(
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
