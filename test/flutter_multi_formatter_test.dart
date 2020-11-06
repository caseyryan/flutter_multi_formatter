import 'package:flutter_test/flutter_test.dart';

import '../lib/flutter_multi_formatter.dart';

void main() {
  test(
      'should use the philippines land line mask (shorter one) when partially entering a number',
      () {
    final inputNumber = '+6355666';
    final formattedNumber = PhoneInputFormatter()
        .formatEditUpdate(
            TextEditingValue(text: ''), TextEditingValue(text: inputNumber))
        .text;
    expect(formattedNumber, '+63 55 666');
  });

  test('should format philippines land line with full number length', () {
    final inputNumber = '+63556667777';
    final formattedNumber = PhoneInputFormatter()
        .formatEditUpdate(
            TextEditingValue(text: ''), TextEditingValue(text: inputNumber))
        .text;
    expect(formattedNumber, '+63 55 666 77 77');
  });

  test('should format philippines mobile number with full number length', () {
    final inputNumber = '+635556667777';
    final formattedNumber = PhoneInputFormatter()
        .formatEditUpdate(
            TextEditingValue(text: ''), TextEditingValue(text: inputNumber))
        .text;
    expect(formattedNumber, '+63 555 666 77 77');
  });

  test('should format US number with full number length', () {
    final inputNumber = '+14444444444';
    final formattedNumber = PhoneInputFormatter()
        .formatEditUpdate(
            TextEditingValue(text: ''), TextEditingValue(text: inputNumber))
        .text;
    expect(formattedNumber, '+1 (444) 444 4444');
  });

  test('should partially format a US number', () {
    final inputNumber = '+14444';
    final formattedNumber = PhoneInputFormatter()
        .formatEditUpdate(
            TextEditingValue(text: ''), TextEditingValue(text: inputNumber))
        .text;
    expect(formattedNumber, '+1 (444) 4');
  });
}
