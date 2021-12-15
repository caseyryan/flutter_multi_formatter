import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/pos_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decimalSeparator = '.';
  const formatter = PosInputFormatter(
    decimalSeparator: DecimalPosSeparator.dot,
    thousandsSeparator: ThousandsPosSeparator.space,
    mantissaLength: 2,
  );

  group('Test PosInputFormatter text input formatter', () {
    group(
        'Tests for adding zeroes at the beginning of the number and adding decimal separator',
        () {
      test('Add "0.0" at the beginning of the string', () {
        const oldValue = TextEditingValue();
        const newValue = TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        );
        const expectedValue = TextEditingValue(
          text: '0${decimalSeparator}01',
          selection: TextSelection.collapsed(offset: 4),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
      test('Add "0." at the beginning of the string', () {
        const oldValue = TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        );
        const newValue = TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        );
        const expectedValue = TextEditingValue(
          text: '0${decimalSeparator}12',
          selection: TextSelection.collapsed(offset: 4),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
      test('Add "." to the string', () {
        const oldValue = TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        );
        const newValue = TextEditingValue(
          text: '123',
          selection: TextSelection.collapsed(offset: 3),
        );
        const expectedValue = TextEditingValue(
          text: '1${decimalSeparator}23',
          selection: TextSelection.collapsed(offset: 4),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
      test('Add "." between 4 digits', () {
        const oldValue = TextEditingValue(
          text: '1.23',
          selection: TextSelection.collapsed(offset: 4),
        );
        const newValue = TextEditingValue(
          text: '1.234',
          selection: TextSelection.collapsed(offset: 5),
        );
        const expectedValue = TextEditingValue(
          text: '12${decimalSeparator}34',
          selection: TextSelection.collapsed(offset: 5),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
    });

    group('Tests for adding the thousands separator', () {
      test('Not add space', () {
        const oldValue = TextEditingValue(
          text: '12.34',
          selection: TextSelection.collapsed(offset: 5),
        );
        const newValue = TextEditingValue(
          text: '12.345',
          selection: TextSelection.collapsed(offset: 6),
        );
        const expectedValue = TextEditingValue(
          text: '123${decimalSeparator}45',
          selection: TextSelection.collapsed(offset: 6),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
      test('Add space to the string', () {
        const oldValue = TextEditingValue(
          text: '123.45',
          selection: TextSelection.collapsed(offset: 5),
        );
        const newValue = TextEditingValue(
          text: '123.456',
          selection: TextSelection.collapsed(offset: 7),
        );
        const expectedValue = TextEditingValue(
          text: '1 234${decimalSeparator}56',
          selection: TextSelection.collapsed(offset: 8),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
      test('Add only one space to the string', () {
        const oldValue = TextEditingValue(
          text: '12 345.67',
          selection: TextSelection.collapsed(offset: 9),
        );
        const newValue = TextEditingValue(
          text: '123 45.678',
          selection: TextSelection.collapsed(offset: 10),
        );
        const expectedValue = TextEditingValue(
          text: '123 456${decimalSeparator}78',
          selection: TextSelection.collapsed(offset: 10),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
      test('Add two space to the string', () {
        const oldValue = TextEditingValue(
          text: '123 456.78',
          selection: TextSelection.collapsed(offset: 10),
        );
        const newValue = TextEditingValue(
          text: '123 456.789',
          selection: TextSelection.collapsed(offset: 11),
        );
        const expectedValue = TextEditingValue(
          text: '1 234 567${decimalSeparator}89',
          selection: TextSelection.collapsed(offset: 12),
        );

        expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
      });
    });

    test('Remove incorrect characters', () {
      const oldValue = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      const newValue = TextEditingValue(
        text: '123d45a.6',
        selection: TextSelection.collapsed(offset: 9),
      );
      const expectedValue = TextEditingValue(
        text: '1 234${decimalSeparator}56',
        selection: TextSelection.collapsed(offset: 8),
      );

      expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
    });
  });
}
