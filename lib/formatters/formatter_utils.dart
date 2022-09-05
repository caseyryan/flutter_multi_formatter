/*
(c) Copyright 2022 Serov Konstantin.

Licensed under the MIT license:

    http://www.opensource.org/licenses/mit-license.php

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
import 'package:flutter/foundation.dart';

import 'money_input_enums.dart';

final RegExp _digitRegExp = RegExp(r'[-0-9]+');
final RegExp _positiveDigitRegExp = RegExp(r'[0-9]+');
final RegExp _digitWithPeriodRegExp = RegExp(r'[-0-9]+(\.[0-9]+)?');
final RegExp _oneDashRegExp = RegExp(r'[-]{2,}');
final RegExp _startPlusRegExp = RegExp(r'^\+{1}[)(\d]+');
final RegExp _maskContentsRegExp = RegExp(r'^[-0-9)( +]{3,}$');
final RegExp _isMaskSymbolRegExp = RegExp(r'^[-\+ )(]+$');
final RegExp _repeatingDotsRegExp = RegExp(r'\.{2,}');

/// [errorText] if you don't want this method to throw any
/// errors, pass null here
/// [allowAllZeroes] might be useful e.g. for phone masks
String toNumericString(
  String? inputString, {
  bool allowPeriod = false,
  bool allowHyphen = true,
  String mantissaSeparator = '.',
  String? errorText,
  bool allowAllZeroes = false,
}) {
  if (inputString == null) {
    return '';
  } else if (inputString == '+') {
    return inputString;
  }
  if (mantissaSeparator == '.') {
    inputString = inputString.replaceAll(',', '');
  } else if (mantissaSeparator == ',') {
    inputString = inputString.replaceAll('.', '').replaceAll(',', '.');
  }
  var startsWithPeriod = numericStringStartsWithOrphanPeriod(
    inputString,
  );

  var regexWithoutPeriod = allowHyphen ? _digitRegExp : _positiveDigitRegExp;
  var regExp = allowPeriod ? _digitWithPeriodRegExp : regexWithoutPeriod;
  var result = inputString.splitMapJoin(
    regExp,
    onMatch: (m) => m.group(0)!,
    onNonMatch: (nm) => '',
  );
  if (startsWithPeriod && allowPeriod) {
    result = '0.$result';
  }
  if (result.isEmpty) {
    return result;
  }
  try {
    result = _toDoubleString(
      result,
      allowPeriod: allowPeriod,
      errorText: errorText,
      allowAllZeroes: allowAllZeroes,
    );
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
  return result;
}

String toNumericStringByRegex(
  String? inputString, {
  bool allowPeriod = false,
  bool allowHyphen = true,
}) {
  if (inputString == null) return '';
  var regexWithoutPeriod = allowHyphen ? _digitRegExp : _positiveDigitRegExp;
  var regExp = allowPeriod ? _digitWithPeriodRegExp : regexWithoutPeriod;
  return inputString.splitMapJoin(
    regExp,
    onMatch: (m) => m.group(0)!,
    onNonMatch: (nm) => '',
  );
}

/// This hack is necessary because double.parse
/// fails at some point
/// while parsing too large numbers starting to convert
/// them into a scientific notation with e+/- power
/// This function doesnt' really care for numbers, it works
/// with strings from the very beginning
/// [input] a value to be converted to a string containing only numbers
/// [allowPeriod] if you need int pass false here
/// [errorText] if you don't want this method to throw an
/// error if a number cannot be formatted
/// pass null
/// [allowAllZeroes] might be useful e.g. for phone masks
String _toDoubleString(
  String input, {
  bool allowPeriod = true,
  String? errorText = 'Invalid number',
  bool allowAllZeroes = false,
}) {
  const period = '.';
  const zero = '0';
  const dash = '-';
  // final allowedSymbols = ['-', period];
  final temp = <String>[];
  if (input.startsWith(period)) {
    if (allowPeriod) {
      temp.add(zero);
    } else {
      return zero;
    }
  }
  bool periodUsed = false;

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (!isDigit(char, positiveOnly: true)) {
      if (char == dash) {
        if (i > 0) {
          if (errorText != null) {
            throw errorText;
          } else {
            continue;
          }
        }
      } else if (char == period) {
        if (!allowPeriod) {
          break;
        } else if (periodUsed) {
          continue;
        }
        periodUsed = true;
      }
    }
    temp.add(char);
  }
  if (temp.contains(period)) {
    while (temp.isNotEmpty && temp[0] == zero) {
      temp.removeAt(0);
    }
    if (temp.isEmpty) {
      return zero;
    } else if (temp[0] == period) {
      temp.insert(0, zero);
    }
  } else {
    if (!allowAllZeroes) {
      while (temp.length > 1) {
        if (temp.first == zero) {
          temp.removeAt(0);
        } else {
          break;
        }
      }
    }
  }
  return temp.join();
}

bool numericStringStartsWithOrphanPeriod(String string) {
  var result = false;
  for (var i = 0; i < string.length; i++) {
    var char = string[i];
    if (isDigit(char)) {
      break;
    }
    if (char == '.' || char == ',') {
      result = true;
      break;
    }
  }
  return result;
}

void checkMask(String mask) {
  if (_oneDashRegExp.hasMatch(mask)) {
    throw ('A mask cannot contain more than one dash (-) symbols in a row');
  }
  if (!_startPlusRegExp.hasMatch(mask)) {
    throw ('A mask must start with a + sign followed by a digit of a rounded brace');
  }
  if (!_maskContentsRegExp.hasMatch(mask)) {
    throw ('A mask can only contain digits, a plus sign, spaces and dashes');
  }
}

/// [thousandSeparator] specifies what symbol will be used to separate
/// each block of 3 digits, e.g. [ThousandSeparator.Comma] will format
/// a million as 1,000,000
/// [shorteningPolicy] is used to round values using K for thousands, M for
/// millions and B for billions
/// [ShorteningPolicy.NoShortening] displays a value of 1234456789.34 as 1,234,456,789.34
/// but [ShorteningPolicy.RoundToThousands] displays the same value as 1,234,456K
/// [mantissaLength] specifies how many digits will be added after a period sign
/// [leadingSymbol] any symbol (except for the ones that contain digits) the will be
/// added in front of the resulting string. E.g. $ or €
/// some of the signs are available via constants like [MoneySymbols.EURO_SIGN]
/// but you can basically add any string instead of it. The main rule is that the string
/// must not contain digits, preiods, commas and dashes
/// [trailingSymbol] is the same as leading but this symbol will be added at the
/// end of your resulting string like 1,250€ instead of €1,250
/// [useSymbolPadding] adds a space between the number and trailing / leading symbols
/// like 1,250€ -> 1,250 € or €1,250€ -> € 1,250
String toCurrencyString(
  String value, {
  int mantissaLength = 2,
  ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
  ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
  String leadingSymbol = '',
  String trailingSymbol = '',
  bool useSymbolPadding = false,
}) {
  var swapCommasAndPreriods = false;
  if (mantissaLength <= 0) {
    mantissaLength = 0;
  }

  String? tSeparator;
  String mantissaSeparator = '.';
  switch (thousandSeparator) {
    case ThousandSeparator.Comma:
      tSeparator = ',';
      break;
    case ThousandSeparator.Period:

      /// yep, comma here is correct
      /// because swapCommasAndPreriods = true it will
      /// swap them all later
      tSeparator = ',';
      swapCommasAndPreriods = true;
      mantissaSeparator = ',';
      break;
    case ThousandSeparator.None:
      tSeparator = '';
      break;
    case ThousandSeparator.SpaceAndPeriodMantissa:
      tSeparator = ' ';
      break;
    case ThousandSeparator.SpaceAndCommaMantissa:
      tSeparator = ' ';
      swapCommasAndPreriods = true;
      mantissaSeparator = ',';
      break;
    case ThousandSeparator.Space:
      tSeparator = ' ';
      break;
  }
  // print(thousandSeparator);
  value = value.replaceAll(_repeatingDotsRegExp, '.');
  value = toNumericString(
    value,
    allowPeriod: mantissaLength > 0,
    mantissaSeparator: mantissaSeparator,
  );
  var isNegative = value.contains('-');

  /// parsing here is done to avoid any unnecessary symbols inside
  /// a number
  var parsed = (double.tryParse(value) ?? 0.0);
  if (parsed == 0.0) {
    if (isNegative) {
      var containsMinus = parsed.toString().contains('-');
      if (!containsMinus) {
        value =
            '-${parsed.toStringAsFixed(mantissaLength).replaceFirst('0.', '.')}';
      } else {
        value = '${parsed.toStringAsFixed(mantissaLength)}';
      }
    } else {
      value = parsed.toStringAsFixed(mantissaLength);
    }
  }
  var noShortening = shorteningPolicy == ShorteningPolicy.NoShortening;

  var minShorteningLength = 0;
  switch (shorteningPolicy) {
    case ShorteningPolicy.NoShortening:
      break;
    case ShorteningPolicy.RoundToThousands:
      minShorteningLength = 4;
      value = '${_getRoundedValue(value, 1000)}K';
      break;
    case ShorteningPolicy.RoundToMillions:
      minShorteningLength = 7;
      value = '${_getRoundedValue(value, 1000000)}M';
      break;
    case ShorteningPolicy.RoundToBillions:
      minShorteningLength = 10;
      value = '${_getRoundedValue(value, 1000000000)}B';
      break;
    case ShorteningPolicy.RoundToTrillions:
      minShorteningLength = 13;
      value = '${_getRoundedValue(value, 1000000000000)}T';
      break;
    case ShorteningPolicy.Automatic:
      // find out what shortening to use base on the length of the string
      var intValStr = (int.tryParse(value) ?? 0).toString();
      if (intValStr.length < 7) {
        minShorteningLength = 4;
        value = '${_getRoundedValue(value, 1000)}K';
      } else if (intValStr.length < 10) {
        minShorteningLength = 7;
        value = '${_getRoundedValue(value, 1000000)}M';
      } else if (intValStr.length < 13) {
        minShorteningLength = 10;
        value = '${_getRoundedValue(value, 1000000000)}B';
      } else {
        minShorteningLength = 13;
        value = '${_getRoundedValue(value, 1000000000000)}T';
      }
      break;
  }
  var list = <String?>[];
  var mantissa = '';
  var split = value.split('');
  var mantissaList = <String>[];
  var mantissaSeparatorIndex = value.indexOf('.');
  if (mantissaSeparatorIndex > -1) {
    var start = mantissaSeparatorIndex + 1;
    var end = start + mantissaLength;
    for (var i = start; i < end; i++) {
      if (i < split.length) {
        mantissaList.add(split[i]);
      } else {
        mantissaList.add('0');
      }
    }
  }

  mantissa = noShortening
      ? _postProcessMantissa(mantissaList.join(''), mantissaLength)
      : '';
  var maxIndex = split.length - 1;
  if (mantissaSeparatorIndex > 0 && noShortening) {
    maxIndex = mantissaSeparatorIndex - 1;
  }
  var digitCounter = 0;
  if (maxIndex > -1) {
    for (var i = maxIndex; i >= 0; i--) {
      digitCounter++;
      list.add(split[i]);
      if (noShortening) {
        // в случае с отрицательным числом, запятая перед минусом не нужна
        if (digitCounter % 3 == 0 && i > (isNegative ? 1 : 0)) {
          list.add(tSeparator);
        }
      } else {
        if (value.length >= minShorteningLength) {
          if (!isDigit(split[i])) digitCounter = 1;
          if (digitCounter % 3 == 1 &&
              digitCounter > 1 &&
              i > (isNegative ? 1 : 0)) {
            list.add(tSeparator);
          }
        }
      }
    }
  } else {
    list.add('0');
  }

  if (leadingSymbol.isNotEmpty) {
    if (useSymbolPadding) {
      list.add('$leadingSymbol ');
    } else {
      list.add(leadingSymbol);
    }
  }
  var reversed = list.reversed.join('');
  String result;

  if (trailingSymbol.isNotEmpty) {
    if (useSymbolPadding) {
      result = '$reversed$mantissa $trailingSymbol';
    } else {
      result = '$reversed$mantissa$trailingSymbol';
    }
  } else {
    result = '$reversed$mantissa';
  }

  if (swapCommasAndPreriods) {
    return _swapCommasAndPeriods(result);
  }
  return result;
}

/// просто меняет точки и запятые местами
String _swapCommasAndPeriods(String input) {
  var temp = input;
  if (temp.indexOf('.,') > -1) {
    temp = temp.replaceAll('.,', ',,');
  }
  temp = temp.replaceAll('.', 'PERIOD').replaceAll(',', 'COMMA');
  temp = temp.replaceAll('PERIOD', ',').replaceAll('COMMA', '.');
  return temp;
}

bool isUnmaskableSymbol(String? symbol) {
  if (symbol == null || symbol.length > 1) {
    return false;
  }
  return _isMaskSymbolRegExp.hasMatch(symbol);
}

String _getRoundedValue(
  String numericString,
  double roundTo,
) {
  assert(roundTo != 0.0);
  var numericValue = double.tryParse(numericString) ?? 0.0;
  var result = numericValue / roundTo;

  /// e.g. for a number of 1700 return 1.7, instead of 1
  /// after rounding to 1000
  var remainder = result.remainder(1.0);
  String prepared;
  if (remainder != 0.0) {
    prepared = result.toStringAsFixed(2);
    if (prepared[prepared.length - 1] == '0') {
      prepared = prepared.substring(0, prepared.length - 1);
    }
    return prepared;
  }
  return result.toInt().toString();
}

/// simply adds a period to an existing fractional part
/// or adds an empty fractional part if it was not filled
String _postProcessMantissa(String mantissaValue, int mantissaLength) {
  if (mantissaLength < 1) return '';
  if (mantissaValue.isNotEmpty) return '.$mantissaValue';
  return '.${List.filled(mantissaLength, '0').join('')}';
}

/// [character] a character to check if it's a digit against
/// [positiveOnly] if true it will not allow a minus (dash) character
/// to be accepted as a part of a digit
bool isDigit(
  String? character, {
  bool positiveOnly = false,
}) {
  if (character == null || character.isEmpty || character.length > 1) {
    return false;
  }
  if (positiveOnly) {
    return _positiveDigitRegExp.stringMatch(character) != null;
  }
  return _digitRegExp.stringMatch(character) != null;
}
