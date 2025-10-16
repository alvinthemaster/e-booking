import 'package:flutter_test/flutter_test.dart';
import 'package:godtrasco_eticket/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('should format peso correctly', () {
      expect(CurrencyFormatter.formatPeso(150.0), '₱150');
      expect(CurrencyFormatter.formatPeso(130.0), '₱130');
    });

    test('should format peso with decimals correctly', () {
      expect(CurrencyFormatter.formatPesoWithDecimals(150.50), '₱150.50');
      expect(CurrencyFormatter.formatPesoWithDecimals(130.00), '₱130.00');
    });

    test('should format discount correctly', () {
      expect(CurrencyFormatter.formatDiscount(20.0), '-₱20.00');
      expect(CurrencyFormatter.formatDiscount(15.50), '-₱15.50');
    });

    test('should format peso compact correctly', () {
      expect(CurrencyFormatter.formatPesoCompact(150.0), '₱150');
      expect(CurrencyFormatter.formatPesoCompact(1500.0), '₱1.5k');
    });

    test('should format price range correctly', () {
      expect(CurrencyFormatter.formatPriceRange(130.0, 150.0), '₱130 - ₱150');
    });

    test('should provide peso symbol', () {
      expect(CurrencyFormatter.pesoSymbol, '₱');
    });

    test('should indicate peso symbol is supported', () {
      expect(CurrencyFormatter.isPesoSymbolSupported, true);
    });
  });
}