/// Generic mutable solo class.
class Solo<T> {
  T value;

  Solo(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) => other is Solo<T> && value == other.value;

  @override
  String toString() => '$value';
}

/// Generic mutable pair class.
class Pair<T1, T2> {
  T1 first;
  T2 second;

  Pair(this.first, this.second);

  @override
  int get hashCode => first.hashCode * 31 + second.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Pair<T1, T2> && first == other.first && second == other.second;

  @override
  String toString() => '($first, $second)';
}

/// Generic mutable triple class.
class Triple<T1, T2, T3> {
  T1 first;
  T2 second;
  T3 third;

  Triple(this.first, this.second, this.third);

  @override
  int get hashCode =>
      first.hashCode * 31 * 31 + second.hashCode * 31 + third.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Triple<T1, T2, T3> &&
      first == other.first &&
      second == other.second &&
      third == other.third;

  @override
  String toString() => '($first, $second, $third)';
}
