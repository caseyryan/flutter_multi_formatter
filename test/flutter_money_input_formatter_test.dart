import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/flutter_multi_formatter.dart';

void main() {
  test('should correctly remove a comma from thousands', () {
    final currentNumber = "1,000.0";
    final inputNumber = "1,00.0";
    final formattedNumber = MoneyInputFormatter()
        .formatEditUpdate(
            TextEditingValue(
                text: currentNumber,
                selection: TextSelection(baseOffset: 4, extentOffset: 5),
                composing: TextRange(start: -1, end: -1)),
            TextEditingValue(
                text: inputNumber,
                selection: TextSelection(baseOffset: 4, extentOffset: 4),
                composing: TextRange(start: -1, end: -1)))
        .text;
    expect(formattedNumber, "100.00");
  });
}
