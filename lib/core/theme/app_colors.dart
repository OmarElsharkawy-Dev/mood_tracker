import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.onMuted,
    required this.border,
    required this.destructive,
    required this.onDestructive,
    required this.moodAwful,
    required this.moodBad,
    required this.moodOkay,
    required this.moodGood,
    required this.moodGreat,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final Color onMuted;
  final Color border;
  final Color destructive;
  final Color onDestructive;

  final Color moodAwful;
  final Color moodBad;
  final Color moodOkay;
  final Color moodGood;
  final Color moodGreat;

  Color forMood(Mood mood) => switch (mood) {
        Mood.awful => moodAwful,
        Mood.bad => moodBad,
        Mood.okay => moodOkay,
        Mood.good => moodGood,
        Mood.great => moodGreat,
      };

  static const light = AppColors(
    primary: Color(0xFF8B5CF6),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC4B5FD),
    onSecondary: Color(0xFF0F172A),
    accent: Color(0xFF059669),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFFAF5FF),
    onBackground: Color(0xFF4C1D95),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF4C1D95),
    muted: Color(0xFFEDEFF9),
    onMuted: Color(0xFF64748B),
    border: Color(0xFFEDE9FE),
    destructive: Color(0xFFDC2626),
    onDestructive: Color(0xFFFFFFFF),
    moodAwful: Color(0xFF8B5CF6),
    moodBad: Color(0xFF7C7BD8),
    moodOkay: Color(0xFF6E9CB9),
    moodGood: Color(0xFF35B097),
    moodGreat: Color(0xFF059669),
  );

  static const dark = AppColors(
    primary: Color(0xFFB5A0FA),
    onPrimary: Color(0xFF1B1230),
    secondary: Color(0xFF9C8CE6),
    onSecondary: Color(0xFFF1EFFB),
    accent: Color(0xFF34D399),
    onAccent: Color(0xFF062C20),
    background: Color(0xFF1B1230),
    onBackground: Color(0xFFF1EFFB),
    surface: Color(0xFF261A40),
    onSurface: Color(0xFFF1EFFB),
    muted: Color(0xFF2F2347),
    onMuted: Color(0xFFB8B0CC),
    border: Color(0xFF3A2D55),
    destructive: Color(0xFFF87171),
    onDestructive: Color(0xFF2A0A0A),
    moodAwful: Color(0xFFB5A0FA),
    moodBad: Color(0xFFA199EA),
    moodOkay: Color(0xFF9CB6D2),
    moodGood: Color(0xFF7DD3B6),
    moodGreat: Color(0xFF34D399),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? onMuted,
    Color? border,
    Color? destructive,
    Color? onDestructive,
    Color? moodAwful,
    Color? moodBad,
    Color? moodOkay,
    Color? moodGood,
    Color? moodGreat,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
      onMuted: onMuted ?? this.onMuted,
      border: border ?? this.border,
      destructive: destructive ?? this.destructive,
      onDestructive: onDestructive ?? this.onDestructive,
      moodAwful: moodAwful ?? this.moodAwful,
      moodBad: moodBad ?? this.moodBad,
      moodOkay: moodOkay ?? this.moodOkay,
      moodGood: moodGood ?? this.moodGood,
      moodGreat: moodGreat ?? this.moodGreat,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      onMuted: Color.lerp(onMuted, other.onMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      moodAwful: Color.lerp(moodAwful, other.moodAwful, t)!,
      moodBad: Color.lerp(moodBad, other.moodBad, t)!,
      moodOkay: Color.lerp(moodOkay, other.moodOkay, t)!,
      moodGood: Color.lerp(moodGood, other.moodGood, t)!,
      moodGreat: Color.lerp(moodGreat, other.moodGreat, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
