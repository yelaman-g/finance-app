import 'package:flutter/services.dart';

/// Живой разделитель тысяч "," для полей ввода суммы. Десятичная часть — через "." (до 2 знаков).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.isEmpty) return newValue;
    // keep only digits and dots
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (text.isEmpty) {
      return const TextEditingValue(text: '');
    }
    // single dot, max 2 decimals
    final firstDot = text.indexOf('.');
    String intPart;
    String decPart = '';
    bool hasDot = false;
    if (firstDot >= 0) {
      hasDot = true;
      intPart = text.substring(0, firstDot).replaceAll('.', '');
      decPart = text.substring(firstDot + 1).replaceAll('.', '');
      if (decPart.length > 2) decPart = decPart.substring(0, 2);
    } else {
      intPart = text;
    }
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), ''); // drop leading zeros (keep single 0)
    final grouped = _group(intPart.isEmpty ? '0' : intPart);
    final formatted = hasDot ? '$grouped.$decPart' : grouped;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _group(String digits) {
    final buf = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

/// Снять разделители для парсинга в число перед отправкой на API.
String unformatAmount(String text) => text.replaceAll(',', '');
