import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.error,
    required this.onError,
    required this.moodAwful,
    required this.moodBad,
    required this.moodOkay,
    required this.moodGood,
    required this.moodGreat,
  });

  // Canonical palette (Daylio-inspired).
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color error;
  final Color onError;

  // Mood scale (identical light + dark).
  final Color moodAwful;
  final Color moodBad;
  final Color moodOkay;
  final Color moodGood;
  final Color moodGreat;

  /// Resolves a [Mood] to its themed color.
  Color moodColor(Mood mood) => switch (mood) {
        Mood.awful => moodAwful,
        Mood.bad => moodBad,
        Mood.okay => moodOkay,
        Mood.good => moodGood,
        Mood.great => moodGreat,
      };

  // Backward-compat shims — kept so widgets still compile until they migrate.
  // Why: this redesign renamed `muted/onMuted/border/destructive/onDestructive`
  // and dropped `accent`. Removing them outright would break ~28 widget files.
  // How to apply: prefer the canonical fields in new code; these getters will
  // be removed once the widget layer is migrated to the new names.
  Color get muted => surfaceVariant;
  Color get onMuted => onSurfaceVariant;
  Color get border => outline;
  Color get accent => secondary;
  Color get destructive => error;
  Color get onDestructive => onError;

  /// Deprecated: use [moodColor]. Kept so existing widgets compile.
  Color forMood(Mood mood) => moodColor(mood);

  static const _moodAwful = Color(0xFFFF6B6B);
  static const _moodBad = Color(0xFFFFA26B);
  static const _moodOkay = Color(0xFFFFD93D);
  static const _moodGood = Color(0xFF6BCB77);
  static const _moodGreat = Color(0xFF4D96FF);

  static const light = AppColors(
    primary: Color(0xFF7C6FCD),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF4ECDC4),
    onSecondary: Color(0xFF0F1021),
    background: Color(0xFFF5F5FA),
    onBackground: Color(0xFF1A1B2E),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF2D2D44),
    surfaceVariant: Color(0xFFEEEEF5),
    onSurfaceVariant: Color(0xFF6E6E8C),
    outline: Color(0xFFDDDDE8),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    moodAwful: _moodAwful,
    moodBad: _moodBad,
    moodOkay: _moodOkay,
    moodGood: _moodGood,
    moodGreat: _moodGreat,
  );

  static const dark = AppColors(
    primary: Color(0xFF7C6FCD),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF4ECDC4),
    onSecondary: Color(0xFF0F1021),
    background: Color(0xFF0F1021),
    onBackground: Color(0xFFE8E8F0),
    surface: Color(0xFF1A1B2E),
    onSurface: Color(0xFFC8C8DC),
    surfaceVariant: Color(0xFF242540),
    onSurfaceVariant: Color(0xFF8888A8),
    outline: Color(0xFF3A3B5C),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFFFFFFFF),
    moodAwful: _moodAwful,
    moodBad: _moodBad,
    moodOkay: _moodOkay,
    moodGood: _moodGood,
    moodGreat: _moodGreat,
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? error,
    Color? onError,
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
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      error: error ?? this.error,
      onError: onError ?? this.onError,
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
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
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
