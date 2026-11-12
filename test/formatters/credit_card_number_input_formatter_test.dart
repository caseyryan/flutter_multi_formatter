import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MIR', () {
    const masks = {
      16: '0000 0000 0000 0000',
      17: '0000 0000 0000 0000 0',
      18: '0000 0000 0000 0000 00',
      19: '0000 0000 0000 0000 000',
    };

    for (final prefix in ['2200', '2201', '2202', '2203', '2204']) {
      for (final length in masks.keys) {
        group('$prefix with $length digits', () {
          final raw = _mirNumber(prefix, length);
          final spaced = _groupByFour(raw);

          test('selects the exact MIR mask', () {
            final data = getCardSystemData(raw)!;
            expect(data.system, CardSystem.MIR);
            expect(data.systemCode, prefix);
            expect(data.numDigits, length);
            expect(data.numberMask, masks[length]);
          });

          test('pastes raw or spaced input with the cursor at the end', () {
            for (final input in [raw, spaced]) {
              expect(_paste(input), _editingValue(spaced), reason: input);
            }
          });

          test('keeps every digit entered sequentially', () {
            final formatter = CreditCardNumberInputFormatter();
            var value = _editingValue('');
            for (var i = 0; i < raw.length; i++) {
              final input = _editingValue(value.text + raw[i]);
              value = formatter.formatEditUpdate(value, input);
              final typed = raw.substring(0, i + 1);
              expect(value, _editingValue(_groupByFour(typed)), reason: typed);
            }
          });

          test('validates the length and checksum', () {
            for (final input in [raw, spaced]) {
              expect(
                isCardNumberValid(cardNumber: input, checkLength: true),
                isTrue,
                reason: input,
              );
            }
          });

          test('formats raw or spaced input through the helper', () {
            expect(formatAsCardNumber(raw), spaced);
            expect(formatAsCardNumber(spaced), spaced);
          });
        });
      }
    }

    test('pastes the full 19-digit number from issue #188', () {
      expect(
        _paste('2201123456789012345'),
        _editingValue('2201 1234 5678 9012 345'),
      );
    });

    for (final entry in const {15: 16, 20: 19}.entries) {
      final length = entry.key;
      final nearestLength = entry.value;
      final number = _mirNumber('2201', length);

      test('selects the $nearestLength-digit mask for $length digits', () {
        final data = getCardSystemData(number)!;
        expect(data.numDigits, nearestLength);
        expect(data.numberMask, masks[nearestLength]);
      });

      test('rejects a $length-digit number with a valid checksum', () {
        expect(
          isCardNumberValid(cardNumber: number, checkLength: true),
          isFalse,
        );
      });
    }

    test('rejects an invalid checksum at a supported length', () {
      final valid = _mirNumber('2201', 19);
      final wrongDigit = (int.parse(valid[18]) + 1) % 10;
      final invalid = '${valid.substring(0, 18)}$wrongDigit';
      expect(
          isCardNumberValid(cardNumber: invalid, checkLength: true), isFalse);
      expect(
        isCardNumberValid(
          cardNumber: invalid,
          checkLength: true,
          useLuhnAlgo: false,
        ),
        isTrue,
      );
      expect(formatAsCardNumber(invalid), '2201 1234 5678 9012');
      expect(formatAsCardNumber(_groupByFour(invalid)), '2201 ');
    });

    test('deletes and retypes across the 19-, 18-, 17- and 16-digit masks', () {
      final formatter = CreditCardNumberInputFormatter();
      const values = [
        '2201 1234 5678 9012 345',
        '2201 1234 5678 9012 34',
        '2201 1234 5678 9012 3',
        '2201 1234 5678 9012',
      ];
      var value = formatter.formatEditUpdate(
        _editingValue(''),
        _editingValue(values.first),
      );

      for (final expected in values.skip(1)) {
        final input = value.text.substring(0, value.text.length - 1);
        value = formatter.formatEditUpdate(value, _editingValue(input));
        expect(value, _editingValue(expected));
      }

      for (final expected in values.reversed.skip(1)) {
        value = formatter.formatEditUpdate(
          value,
          _editingValue(value.text + expected[expected.length - 1]),
        );
        expect(value, _editingValue(expected));
      }
    });

    test('keeps the cursor beside a middle edit across 17 and 16 digits', () {
      final formatter = CreditCardNumberInputFormatter();
      final initial = _editingValue('2201 1234 5678 9012 3', 12);
      final deleted = formatter.formatEditUpdate(
        initial,
        _editingValue('2201 1234 578 9012 3', 11),
      );
      expect(deleted, _editingValue('2201 1234 5789 0123', 11));

      final reinserted = formatter.formatEditUpdate(
        deleted,
        _editingValue('2201 1234 56789 0123', 12),
      );
      expect(reinserted, initial);
    });

    test('keeps the cursor after a retained space during forward delete', () {
      final result = CreditCardNumberInputFormatter().formatEditUpdate(
        _editingValue('2201 1234 5678 9012 3', 10),
        _editingValue('2201 1234 678 9012 3', 10),
      );
      expect(result, _editingValue('2201 1234 6789 0123', 10));
    });

    test('keeps the cursor beside a digit deleted before the final space', () {
      final formatter = CreditCardNumberInputFormatter();
      final initial = _editingValue('2201 1234 5678 9012 3', 19);
      final deleted = formatter.formatEditUpdate(
        initial,
        _editingValue('2201 1234 5678 901 3', 18),
      );
      expect(deleted, _editingValue('2201 1234 5678 9013', 18));

      final reinserted = formatter.formatEditUpdate(
        deleted,
        _editingValue('2201 1234 5678 90123', 19),
      );
      expect(reinserted, initial);
    });

    for (final suffix in ['', ' 345']) {
      final previous = '2201 1234 5678 9012$suffix';
      final expected = '2202 1234 5678 9012$suffix';
      final raw = expected.replaceAll(' ', '');
      test('pastes over a selected ${raw.length}-digit number', () {
        final selection = TextEditingValue(
          text: previous,
          selection:
              TextSelection(baseOffset: 0, extentOffset: previous.length),
        );
        final result = CreditCardNumberInputFormatter().formatEditUpdate(
          selection,
          _editingValue(raw),
        );
        expect(result, _editingValue(expected));
      });
    }

    test('limits overlong raw and spaced paste to 19 digits', () {
      const expected = '2201 1234 5678 9012 345';
      expect(_paste('22011234567890123456'), _editingValue(expected));
      expect(_paste('2201 1234 5678 9012 3456'), _editingValue(expected));
    });

    test('rejects a twentieth digit typed into a full number', () {
      const number = '2201 1234 5678 9012 345';
      final formatter = CreditCardNumberInputFormatter();
      final full = formatter.formatEditUpdate(
        _editingValue(''),
        _editingValue(number),
      );
      expect(
        formatter.formatEditUpdate(full, _editingValue('${number}6')),
        full,
      );

      final cursorInMiddle = _editingValue(number, 11);
      expect(
        formatter.formatEditUpdate(
          cursorInMiddle,
          _editingValue('2201 1234 50678 9012 345', 12),
        ),
        cursorInMiddle,
      );
    });
  });

  group('Other card systems', () {
    const cases = [
      _CardExample(CardSystem.UNION_PAY, '62', '6200 1234 5678 9012',
          '0000 0000 0000 0000'),
      _CardExample(CardSystem.UNION_PAY, '62', '6200 1234 5678 9012 345',
          '0000 0000 0000 0000 000'),
      _CardExample(CardSystem.MAESTRO, '67', '6700 1234 5678 9012 3',
          '0000 0000 0000 0000 0'),
      _CardExample(CardSystem.MAESTRO, '67', '67001234 5678901234',
          '00000000 0000000000'),
      _CardExample(CardSystem.AMERICAN_EXPRESS, '34', '3400 123456 78901',
          '0000 000000 00000'),
      _CardExample(
          CardSystem.DINERS_CLUB, '36', '3600 123456 7890', '0000 000000 0000'),
    ];

    for (final example in cases) {
      final raw = example.formatted.replaceAll(' ', '');
      test('${example.system} keeps its ${raw.length}-digit mask', () {
        final data = getCardSystemData(raw)!;
        expect(data.system, example.system);
        expect(data.systemCode, example.prefix);
        expect(data.numDigits, raw.length);
        expect(data.numberMask, example.mask);
        expect(_paste(raw), _editingValue(example.formatted));

        final valid = _withCheckDigit(raw.substring(0, raw.length - 1));
        expect(
          isCardNumberValid(cardNumber: valid, checkLength: true),
          isTrue,
        );
      });
    }

    test('Discover keeps its existing 16- and 19-digit mask selection', () {
      const short = '6012345678901234';
      const long = '${short}567';
      final shorter = getCardSystemData(short)!;
      final longer = getCardSystemData(long)!;
      expect(shorter.system, CardSystem.DISCOVER);
      expect(longer.system, CardSystem.DISCOVER);
      expect(shorter.numDigits, 16);
      expect(longer.numDigits, 19);
      expect(shorter.numberMask, '0000 0000 0000 0000');
      expect(longer.numberMask, '0000 0000 0000 0000');
      expect(_paste(long), _editingValue('6012 3456 7890 1234'));
    });
  });
}

class _CardExample {
  const _CardExample(this.system, this.prefix, this.formatted, this.mask);

  final String system;
  final String prefix;
  final String formatted;
  final String mask;
}

TextEditingValue _editingValue(String text, [int? offset]) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: offset ?? text.length),
  );
}

TextEditingValue _paste(String input) {
  return CreditCardNumberInputFormatter().formatEditUpdate(
    _editingValue(''),
    _editingValue(input),
  );
}

String _groupByFour(String digits) {
  return RegExp(r'.{1,4}')
      .allMatches(digits)
      .map((match) => match.group(0)!)
      .join(' ');
}

String _mirNumber(String prefix, int length) {
  return _withCheckDigit('${prefix}123456789012345'.substring(0, length - 1));
}

String _withCheckDigit(String body) {
  const doubledDigits = [0, 2, 4, 6, 8, 1, 3, 5, 7, 9];
  var sum = 0;
  for (var i = 0; i < body.length; i++) {
    final digit = int.parse(body[i]);
    sum += i.isEven == body.length.isOdd ? doubledDigits[digit] : digit;
  }
  return '$body${(10 - sum % 10) % 10}';
}
