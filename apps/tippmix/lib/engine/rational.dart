/// Exact rational arithmetic (BigInt). Display rounding happens only at the UI edge.
class Rational implements Comparable<Rational> {
  final BigInt n;
  final BigInt d;

  Rational._(this.n, this.d);

  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var den = denominator ?? BigInt.one;
    if (den == BigInt.zero) {
      throw ArgumentError.value(den, 'denominator', 'division by zero');
    }
    if (den < BigInt.zero) {
      numerator = -numerator;
      den = -den;
    }
    if (numerator == BigInt.zero) {
      return Rational._(BigInt.zero, BigInt.one);
    }
    final g = numerator.abs().gcd(den);
    return Rational._(numerator ~/ g, den ~/ g);
  }

  factory Rational.fromInt(int value) => Rational(BigInt.from(value));

  static final zero = Rational.fromInt(0);
  static final one = Rational.fromInt(1);

  /// Parses decimal odds such as `2.40` or Hungarian `1,85` into an exact fraction.
  factory Rational.parseDecimal(String input) {
    final trimmed = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (trimmed.isEmpty) {
      throw const FormatException('empty');
    }
    var s = trimmed;
    var negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    if (s.contains('e') || s.contains('E') || s.contains('/')) {
      throw FormatException('unsupported number format', input);
    }
    final parts = s.split('.');
    if (parts.length > 2) {
      throw FormatException('invalid decimal', input);
    }
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length == 2 ? parts[1] : '';
    if (!RegExp(r'^\d+$').hasMatch(whole) ||
        (frac.isNotEmpty && !RegExp(r'^\d+$').hasMatch(frac))) {
      throw FormatException('invalid decimal', input);
    }
    final digits = whole + frac;
    final denom = BigInt.from(10).pow(frac.length);
    var num = BigInt.parse(digits);
    if (negative) num = -num;
    return Rational(num, denom);
  }

  Rational operator +(Rational other) =>
      Rational(n * other.d + other.n * d, d * other.d);

  Rational operator -(Rational other) =>
      Rational(n * other.d - other.n * d, d * other.d);

  Rational operator *(Rational other) => Rational(n * other.n, d * other.d);

  Rational operator /(Rational other) {
    if (other.n == BigInt.zero) {
      throw ArgumentError('division by zero');
    }
    return Rational(n * other.d, d * other.n);
  }

  Rational operator -() => Rational(-n, d);

  bool get isZero => n == BigInt.zero;

  Rational get inverse {
    if (n == BigInt.zero) {
      throw ArgumentError('division by zero');
    }
    return Rational(d, n);
  }

  @override
  int compareTo(Rational other) => (n * other.d).compareTo(other.n * d);

  bool operator <(Rational other) => compareTo(other) < 0;
  bool operator <=(Rational other) => compareTo(other) <= 0;
  bool operator >(Rational other) => compareTo(other) > 0;
  bool operator >=(Rational other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Rational && n == other.n && d == other.d;

  @override
  int get hashCode => Object.hash(n, d);

  /// Display-only. Engine tests must compare [Rational] values, not this.
  double toDouble() => n / d;

  /// Hungarian percent, e.g. `12,34%`. Rounding is display-only (half away from 0).
  String toPercentString({int decimals = 2}) {
    final scaled = this * Rational.fromInt(100);
    return '${_formatFixed(scaled, decimals)}%';
  }

  /// Hungarian decimal, e.g. `2,40`.
  String toDecimalString({int decimals = 2}) => _formatFixed(this, decimals);

  static String _formatFixed(Rational value, int decimals) {
    if (decimals < 0) {
      throw ArgumentError.value(decimals);
    }
    final sign = value.n < BigInt.zero ? '-' : '';
    final abs = Rational(value.n.abs(), value.d);
    final factor = BigInt.from(10).pow(decimals);
    final scaled = abs * Rational(factor);
    final whole = scaled.n ~/ scaled.d;
    final rem = scaled.n % scaled.d;
    var rounded = whole;
    if (rem * BigInt.two >= scaled.d) {
      rounded += BigInt.one;
    }
    final pow = BigInt.from(10).pow(decimals);
    var intPart = rounded ~/ pow;
    var fracPart = rounded % pow;
    if (decimals > 0 && fracPart == pow) {
      intPart += BigInt.one;
      fracPart = BigInt.zero;
    }
    if (decimals == 0) {
      return '$sign$intPart';
    }
    final frac = fracPart.toString().padLeft(decimals, '0');
    return '$sign$intPart,$frac';
  }

  @override
  String toString() => d == BigInt.one ? n.toString() : '$n/$d';
}
