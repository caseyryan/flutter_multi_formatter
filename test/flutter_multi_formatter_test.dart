import 'package:flutter/services.dart';
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

  group('showCountryCode', () {
    test('default behavior (showCountryCode: true) shows country code', () {
      final inputNumber = '+5511999999999';
      final formattedNumber = PhoneInputFormatter()
          .formatEditUpdate(
            TextEditingValue(text: ''),
            TextEditingValue(text: inputNumber),
          )
          .text;
      expect(formattedNumber, '+55 (11) 99999-9999');
    });

    test('showCountryCode: false hides country code for BR number', () {
      final inputNumber = '+5511999999999';
      final formattedNumber =
          PhoneInputFormatter(showCountryCode: false)
              .formatEditUpdate(
                TextEditingValue(text: ''),
                TextEditingValue(text: inputNumber),
              )
              .text;
      expect(formattedNumber, '(11) 99999-9999');
    });

    test('showCountryCode: false hides country code for US number', () {
      final inputNumber = '+14444444444';
      final formattedNumber =
          PhoneInputFormatter(showCountryCode: false)
              .formatEditUpdate(
                TextEditingValue(text: ''),
                TextEditingValue(text: inputNumber),
              )
              .text;
      expect(formattedNumber, '(444) 444 4444');
    });

    test('showCountryCode: false handles partial input', () {
      final inputNumber = '+5511';
      // An explicit selection is required here because with showCountryCode: false
      // the masked output is shorter than the raw input (country-code digits are
      // hidden), so the default invalid selection (end = -1) would produce a
      // negative selectionEnd and trigger a Flutter assertion.
      final formattedNumber =
          PhoneInputFormatter(showCountryCode: false)
              .formatEditUpdate(
                TextEditingValue(text: ''),
                TextEditingValue(
                  text: inputNumber,
                  selection: TextSelection.collapsed(offset: inputNumber.length),
                ),
              )
              .text;
      expect(formattedNumber, '(11');
    });

    test('unmasked getter returns full international number when showCountryCode: false', () {
      final inputNumber = '+5511999999999';
      final formatter = PhoneInputFormatter(showCountryCode: false);
      formatter.formatEditUpdate(
        TextEditingValue(text: ''),
        TextEditingValue(text: inputNumber),
      );
      expect(formatter.unmasked, '+5511999999999');
    });

    test('formatAsPhoneNumber with showCountryCode: false hides country code', () {
      final result = formatAsPhoneNumber(
        '+5511999999999',
        showCountryCode: false,
      );
      expect(result, '(11) 99999-9999');
    });

    test('isPhoneValid still works for full number', () {
      expect(isPhoneValid('+5511999999999'), isTrue);
    });

    group('combined with defaultCountryCode', () {
      // When defaultCountryCode is set, showCountryCode: false has no additional
      // effect on the masked output (defaultCountryCode already hides the prefix),
      // but unmasked should still return the full international number.
      test('masked output is unaffected — defaultCountryCode already hides prefix', () {
        final formattedNumber =
            PhoneInputFormatter(defaultCountryCode: 'BR', showCountryCode: false)
                .formatEditUpdate(
                  TextEditingValue(text: ''),
                  TextEditingValue(text: '11999999999'),
                )
                .text;
        expect(formattedNumber, '(11) 99999-9999');
      });

      test('unmasked returns full international number', () {
        final formatter =
            PhoneInputFormatter(defaultCountryCode: 'BR', showCountryCode: false);
        formatter.formatEditUpdate(
          TextEditingValue(text: ''),
          TextEditingValue(text: '11999999999'),
        );
        expect(formatter.unmasked, '+5511999999999');
      });
    });
  });
}
