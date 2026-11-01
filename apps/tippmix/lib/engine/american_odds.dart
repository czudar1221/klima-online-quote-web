import 'rational.dart';

/// American moneyline → decimal odds, exact.
/// +150 → 5/2, −150 → 5/3.
Rational decimalFromAmerican(int american) {
  if (american == 0) {
    throw ArgumentError('american odds cannot be 0');
  }
  if (american > 0) {
    return Rational.fromInt(american) / Rational.fromInt(100) + Rational.one;
  }
  return Rational.fromInt(100) / Rational.fromInt(-american) + Rational.one;
}

int? parseAmerican(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw == 0 ? null : raw;
  if (raw is num) {
    final v = raw.round();
    return v == 0 ? null : v;
  }
  if (raw is String) {
    final s = raw.trim().replaceAll('−', '-');
    if (s.isEmpty || s == '0') return null;
    return int.tryParse(s);
  }
  return null;
}

int? americanFromNested(Map<dynamic, dynamic>? node) {
  if (node == null) return null;
  return parseAmerican(node['close']?['odds']) ??
      parseAmerican(node['odds']) ??
      parseAmerican(node['moneyLine']) ??
      parseAmerican(node['moneyline']);
}
