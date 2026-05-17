enum Mood {
  awful,
  bad,
  okay,
  good,
  great;

  /// 1..5 scoring used by aggregations and chart math.
  int get score => index + 1;
}
