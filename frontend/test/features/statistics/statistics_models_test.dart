import 'package:aifb/features/statistics/data/models/statistics_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendPointModel.fromJson', () {
    test('parses actual backend shape correctly', () {
      // Backend returns: TrendPointResponse(String month, BigDecimal income, BigDecimal expense)
      // Jackson serialises BigDecimal as a JSON number.
      final json = <String, dynamic>{
        'month': '2025-06',
        'income': 150000,
        'expense': 87500,
      };

      final model = TrendPointModel.fromJson(json);

      expect(model.month, '2025-06');
      expect(model.income, 150000.0);
      expect(model.expense, 87500.0);
    });

    test('parses decimal amounts (BigDecimal serialised with fraction)', () {
      final json = <String, dynamic>{
        'month': '2025-07',
        'income': 120000.50,
        'expense': 63400.75,
      };

      final model = TrendPointModel.fromJson(json);

      expect(model.month, '2025-07');
      expect(model.income, closeTo(120000.50, 0.001));
      expect(model.expense, closeTo(63400.75, 0.001));
    });

    test('parses zero values (no transactions in month)', () {
      final json = <String, dynamic>{
        'month': '2025-08',
        'income': 0,
        'expense': 0,
      };

      final model = TrendPointModel.fromJson(json);

      expect(model.month, '2025-08');
      expect(model.income, 0.0);
      expect(model.expense, 0.0);
    });
  });
}
