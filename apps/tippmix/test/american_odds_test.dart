import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/engine/american_odds.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';

void main() {
  test('pozitív american pontos tizedesre', () {
    expect(decimalFromAmerican(150), Rational(BigInt.from(5), BigInt.two));
    expect(decimalFromAmerican(100), Rational.fromInt(2));
  });

  test('negatív american pontos tizedesre', () {
    expect(decimalFromAmerican(-150), Rational(BigInt.from(5), BigInt.from(3)));
  });

  test('parse +185 és 185', () {
    expect(parseAmerican('+185'), 185);
    expect(parseAmerican(185), 185);
    expect(parseAmerican('-150'), -150);
  });
}
