import 'package:aifb/core/utils/thousands_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _val(String text) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

String _format(String input) {
  const formatter = ThousandsSeparatorInputFormatter();
  return formatter
      .formatEditUpdate(const TextEditingValue(text: ''), _val(input))
      .text;
}

void main() {
  group('ThousandsSeparatorInputFormatter', () {
    group('integer grouping progression', () {
      test('1 → 1', () => expect(_format('1'), '1'));
      test('10 → 10', () => expect(_format('10'), '10'));
      test('100 → 100', () => expect(_format('100'), '100'));
      test('1000 → 1,000', () => expect(_format('1000'), '1,000'));
      test('10000 → 10,000', () => expect(_format('10000'), '10,000'));
      test('100000 → 100,000', () => expect(_format('100000'), '100,000'));
      test('1000000 → 1,000,000', () => expect(_format('1000000'), '1,000,000'));
    });

    group('decimal support', () {
      test('1000.5 → 1,000.5', () => expect(_format('1000.5'), '1,000.5'));
      test('1234567.89 → 1,234,567.89', () => expect(_format('1234567.89'), '1,234,567.89'));
      test('1000. → 1,000. (trailing dot kept)', () => expect(_format('1000.'), '1,000.'));
      test('caps to 2 decimal digits: 1000.123 → 1,000.12', () => expect(_format('1000.123'), '1,000.12'));
    });

    group('leading-zero handling', () {
      test('01 → 1', () => expect(_format('01'), '1'));
      test('007 → 7', () => expect(_format('007'), '7'));
      test('0 → 0', () => expect(_format('0'), '0'));
      test('00 → 0', () => expect(_format('00'), '0'));
    });

    group('empty / non-digit input', () {
      test('empty → empty', () => expect(_format(''), ''));
      test('letters stripped → empty', () => expect(_format('abc'), ''));
    });

    group('cursor placed at end', () {
      test('formatted text length == selection offset', () {
        const formatter = ThousandsSeparatorInputFormatter();
        final result = formatter.formatEditUpdate(
          const TextEditingValue(text: ''),
          _val('1000000'),
        );
        expect(result.selection.baseOffset, result.text.length);
      });
    });
  });

  group('unformatAmount', () {
    test("strips commas: '1,234,567.89' → '1234567.89'",
        () => expect(unformatAmount('1,234,567.89'), '1234567.89'));
    test("no commas: '1234' → '1234'",
        () => expect(unformatAmount('1234'), '1234'));
    test("empty → empty", () => expect(unformatAmount(''), ''));
    test("already clean decimal: '0.5' → '0.5'",
        () => expect(unformatAmount('0.5'), '0.5'));
  });
}
