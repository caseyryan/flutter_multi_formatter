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

  test('unknown number without default mask', () {
    final inputNumber = '+999444';
    final withoutDefault = formatAsPhoneNumber(
      inputNumber,
      allowEndlessPhone: true,
    );
    expect(withoutDefault, inputNumber);
  });

  test('unknown number with default mask', () {
    final inputNumber = '+999444';
    final withDefault = formatAsPhoneNumber(
      inputNumber,
      allowEndlessPhone: true,
      defaultMask: '+00 0000 000 000',
    );
    expect(withDefault, '+99 9444');
  });

  test('known number and default mask', () {
    final inputNumber = '+112345';
    final formatted = '+1 (123) 45';
    final withDefault = formatAsPhoneNumber(
      inputNumber,
      allowEndlessPhone: true,
      defaultMask: '+00 0000 000 000',
    );
    expect(withDefault, formatted);

    final withoutDefault = formatAsPhoneNumber(
      inputNumber,
      allowEndlessPhone: true,
    );
    expect(withoutDefault, formatted);
  });

  group('congo', () {
    group('242', () {
      test('should format partial congo mask +000 00', () {
        final inputNumber = '+24255';

        final formattedNumber = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: inputNumber),
            )
            .text;

        expect(formattedNumber, '+242 55');
      });

      test('should format partial congo mask +000 00 00', () {
        final inputNumber = '+2425566';

        final formattedNumber = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: inputNumber),
            )
            .text;

        expect(formattedNumber, '+242 55 66');
      });

      test('should format full congo mask +000 00 00 00000', () {
        final inputNumber = '+242556677777';

        final formattedNumber = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: inputNumber),
            )
            .text;

        expect(formattedNumber, '+242 55 66 77777');
      });
    });

    group('243', () {
      test('should format partial congo mask +000 00', () {
        final inputNumber = '+24355';

        final formattedNumber = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: inputNumber),
            )
            .text;

        expect(formattedNumber, '+243 55');
      });

      test('should format partial congo mask +000 00 00', () {
        final inputNumber = '+2435566';

        final formattedNumber = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: inputNumber),
            )
            .text;

        expect(formattedNumber, '+243 55 66');
      });

      test('should format full congo mask +000 00 00 00000', () {
        final inputNumber = '+243556677777';

        final formattedNumber = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: inputNumber),
            )
            .text;

        expect(formattedNumber, '+243 55 66 77777');
      });
    });
  });
}
