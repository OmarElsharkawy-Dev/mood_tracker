/// Marker for "no value" returns, paired with `(Unit?, Failure?)`.
class Unit {
  const Unit._();
  static const Unit value = Unit._();
}

/// Convenience builders so call-sites stay readable.
typedef Result<T> = (T?, Object?);
