import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/engine/probability.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';

void main() {
  group('Rational', () {
    test('parses decimal and Hungarian comma exactly', () {
      expect(Rational.parseDecimal('2.40'), Rational(BigInt.from(12), BigInt.from(5)));
      expect(Rational.parseDecimal('1,85'), Rational.parseDecimal('1.85'));
      expect(Rational.parseDecimal('2'), Rational.fromInt(2));
    });

    test('arithmetic stays exact', () {
      final a = Rational.parseDecimal('0.1');
      final b = Rational.parseDecimal('0.2');
      expect(a + b, Rational.parseDecimal('0.3'));
      expect((a + b) * Rational.fromInt(10), Rational.fromInt(3));
    });
  });

  group('implied odds and overround', () {
    test('implied probability is exactly 1/odds', () {
      final odds = Rational.parseDecimal('2.50');
      expect(odds.inverse, Rational(BigInt.from(2), BigInt.from(5)));
    });

    test('fair probabilities sum to exactly 1 after overround removal', () {
      final market = MarketProbabilities.fromDecimalOdds([
        Rational.parseDecimal('1,85'),
        Rational.parseDecimal('3,40'),
        Rational.parseDecimal('4,20'),
      ]);
      var sumFair = Rational.zero;
      var sumImplied = Rational.zero;
      for (var i = 0; i < 3; i++) {
        expect(market.implied[i], market.odds[i].inverse);
        expect(market.fair[i] * market.overround, market.implied[i]);
        sumFair += market.fair[i];
        sumImplied += market.implied[i];
      }
      expect(sumFair, Rational.one);
      expect(market.overround, sumImplied);
      expect(market.overround > Rational.one, isTrue);
    });

    test('even book 2.00 / 2.00 has no margin', () {
      final market = MarketProbabilities.fromDecimalOdds([
        Rational.fromInt(2),
        Rational.fromInt(2),
      ]);
      expect(market.overround, Rational.one);
      expect(market.fair[0], Rational(BigInt.one, BigInt.two));
      expect(market.fair[1], Rational(BigInt.one, BigInt.two));
    });
  });

  group('independent events combinatorics', () {
    test('distribution sums to exactly 1', () {
      final events = IndependentEvents([
        Rational.parseDecimal('0.4'),
        Rational.parseDecimal('0.25'),
        Rational.parseDecimal('0.8'),
      ]);
      final dist = events.distributionExactlyK();
      var sum = Rational.zero;
      for (final p in dist) {
        sum += p;
      }
      expect(sum, Rational.one);
    });

    test('two fair coins: P(exactly 1) = 1/2', () {
      final half = Rational(BigInt.one, BigInt.two);
      final events = IndependentEvents([half, half]);
      expect(events.probabilityExactly(0), Rational(BigInt.one, BigInt.from(4)));
      expect(events.probabilityExactly(1), half);
      expect(events.probabilityExactly(2), Rational(BigInt.one, BigInt.from(4)));
      expect(events.accumulator, Rational(BigInt.one, BigInt.from(4)));
      expect(events.probabilityAtLeast(2), events.accumulator);
    });

    test('accumulator equals product of fair probs', () {
      final marketA = MarketProbabilities.fromDecimalOdds([
        Rational.parseDecimal('2.00'),
        Rational.parseDecimal('3.50'),
        Rational.parseDecimal('3.80'),
      ]);
      final marketB = MarketProbabilities.fromDecimalOdds([
        Rational.parseDecimal('1.80'),
        Rational.parseDecimal('3.60'),
        Rational.parseDecimal('4.50'),
      ]);
      final p = marketA.fair[0];
      final q = marketB.fair[2];
      final events = IndependentEvents([p, q]);
      expect(events.accumulator, p * q);
      expect(events.probabilityAtLeast(2), p * q);
      expect(
        events.probabilityAtLeast(1),
        p * q + p * (Rational.one - q) + (Rational.one - p) * q,
      );
    });

    test('P(at least 0) is 1 and P(at least n+1) is 0', () {
      final events = IndependentEvents([
        Rational.parseDecimal('0.3'),
        Rational.parseDecimal('0.6'),
      ]);
      expect(events.probabilityAtLeast(0), Rational.one);
      expect(events.probabilityAtLeast(3), Rational.zero);
    });
  });
}
