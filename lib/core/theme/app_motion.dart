abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  /// Exit ≈ 70% of enter, per design system rule.
  static Duration exit(Duration enter) =>
      Duration(milliseconds: (enter.inMilliseconds * 0.7).round());
}
