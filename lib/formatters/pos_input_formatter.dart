import 'package:flutter/services.dart';

class PosInputFormatter implements TextInputFormatter {
  final DecimalPosSeparator decimalSeparator;
  final ThousandsPosSeparator? thousandsSeparator;
  final int mantissaLength;

  /// [decimalSeparator] specifies what symbol will be used to separate
  /// integer part between decimal part, e.g. [ThousandsPosSeparator.comma]
  /// will format ten point thirteen as 10.13
  /// [thousandsSeparator] specifies what symbol will be used to separate
  /// each block of 3 digits, e.g. [ThousandsPosSeparator.comma] will format
  /// million as 1,000,000
  /// [mantissaLength] specifies how many digits will be added after a period sign
  const PosInputFormatter({
    this.decimalSeparator = DecimalPosSeparator.dot,
    this.thousandsSeparator,
    this.mantissaLength = 2,
  });

  String insertThousandSeparator(
    String text,
    String separator,
  ) {
    final textLength = text.length;
    final textBuffer = <String>[];

    for (var i = 0; i < textLength; i++) {
      if (i % 3 == 0 && i != 0) {
        textBuffer.add(separator);
      }
      textBuffer.add(text[textLength - i - 1]);
    }

    return textBuffer.reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Clean text
    text = text.replaceAll(
      RegExp(r"[^0-9]"),
      '',
    );

    // Remove initial zero
    text = text.replaceFirst(
      RegExp(r'0*'),
      '',
    );

    // Add the zeros until you get to the whole part
    if (text.length <= mantissaLength)
      text = text.padLeft(
        mantissaLength + 1,
        '0',
      );

    if (text.length > mantissaLength) {
      final separatorOffset = text.length - mantissaLength;

      var integerPart = text.substring(
        0,
        separatorOffset,
      );
      final decimalPart = text.substring(
        separatorOffset,
        text.length,
      );

      if (thousandsSeparator != null) {
        integerPart = insertThousandSeparator(
          integerPart,
          thousandsSeparator!.char,
        );
      }

      text = '$integerPart${decimalSeparator.char}$decimalPart';

      return newValue.copyWith(
        selection: TextSelection.collapsed(
          offset: text.length,
        ),
        text: text,
      );
    }

    return newValue.copyWith(
      selection: TextSelection.collapsed(
        offset: text.length,
      ),
      text: text,
    );
  }
}

class DecimalPosSeparator {
  final String char;

  const DecimalPosSeparator._(this.char);

  factory DecimalPosSeparator.parse(
    String char,
  ) {
    switch (char) {
      case ',':
        return comma;
      case '.':
        return dot;
    }

    throw FormatException(
      "Invalid char. Valid characters: $values",
      char,
    );
  }

  /// [comma] means this format 1000000.00
  static const DecimalPosSeparator dot = DecimalPosSeparator._('.');

  /// [comma] means this format 1000000,00
  static const DecimalPosSeparator comma = DecimalPosSeparator._(',');

  /// All decimal pos separators
  static List<DecimalPosSeparator> get values => const [comma, dot];

  @override
  String toString() => '$runtimeType.$char';
}

class ThousandsPosSeparator {
  final String char;

  const ThousandsPosSeparator._(this.char);

  /// Parse [char] to thousands pos separator
  factory ThousandsPosSeparator.parse(String char) {
    switch (char) {
      case ',':
        return comma;
      case '.':
        return dot;
      case ' ':
        return space;
      case '\'':
        return quote;
    }

    throw FormatException(
      "Invalid char. Valid characters: $values",
      char,
    );
  }

  /// [dot] means this format 1.000.000,00
  static const ThousandsPosSeparator dot = ThousandsPosSeparator._('.');

  /// [comma] means this format 1,000,000.00
  static const ThousandsPosSeparator comma = ThousandsPosSeparator._(',');

  /// [space] means this format 1 000 000,00
  static const ThousandsPosSeparator space = ThousandsPosSeparator._(' ');

  /// [space] means this format 1'000'000,00
  static const ThousandsPosSeparator quote = ThousandsPosSeparator._('\'');

  /// All thousands pos separators
  static List<ThousandsPosSeparator> get values => const [comma, dot];

  @override
  String toString() => '$runtimeType.$char';
}
