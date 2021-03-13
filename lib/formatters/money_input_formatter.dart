/*
(c) Copyright 2020 Serov Konstantin.

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

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'formatter_utils.dart';
import 'money_input_enums.dart';

final RegExp _repeatingDots = RegExp(r'\.{2,}');
final RegExp _repeatingCommas = RegExp(r',{2,}');
final RegExp _repeatingSpaces = RegExp(r'\s{2,}');

class MoneySymbols {
  static const String DOLLAR_SIGN = '\$';
  static const String EURO_SIGN = '€';
  static const String POUND_SIGN = '£';
  static const String YEN_SIGN = '￥';
  static const String ETHERIUM_SIGN = 'Ξ';
  static const String BITCOIN_SIGN = 'Ƀ';
  static const String SWISS_FRANK_SIGN = '₣';
  static const String RUBLE_SIGN = '₽';
}

class MoneyInputFormatter extends TextInputFormatter {
  @Deprecated('use MoneySymbols.DOLLAR_SIGN instead')
  static const String DOLLAR_SIGN = '\$';
  @Deprecated('use MoneySymbols.EURO_SIGN instead')
  static const String EURO_SIGN = '€';
  @Deprecated('use MoneySymbols.POUND_SIGN instead')
  static const String POUND_SIGN = '£';
  @Deprecated('use MoneySymbols.YEN_SIGN instead')
  static const String YEN_SIGN = '￥';

  final ThousandSeparator thousandSeparator;
  final int mantissaLength;
  final String leadingSymbol;
  final String trailingSymbol;
  final bool useSymbolPadding;
  final int? maxTextLength;
  final ValueChanged<double>? onValueChange;

  /// [thousandSeparator] specifies what symbol will be used to separate
  /// each block of 3 digits, e.g. [ThousandSeparator.Comma] will format
  /// million as 1,000,000
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
  /// [onValueChange] a callback that will be called on a number change
  MoneyInputFormatter({
    this.thousandSeparator = ThousandSeparator.Comma,
    this.mantissaLength = 2,
    this.leadingSymbol = '',
    this.trailingSymbol = '',
    this.useSymbolPadding = false,
    this.onValueChange,
    this.maxTextLength,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    int leadingLength = leadingSymbol.length;
    int trailingLength = trailingSymbol.length;
    if (leadingLength > 0 && trailingLength > 0) {
      throw 'You cannot use trailing an leading symbols at the same time';
    }
    var newText = newValue.text;
    var oldText = oldValue.text;
    if (oldValue == newValue) {
      return newValue;
    }
    if (newText.contains(',.') || newText.contains('..')) {
      /// this condition is processing a case when you press a period
      /// after the cursor is already located in a mantissa part
      return oldValue.copyWith(
        selection: newValue.selection,
      );
    }

    newText = _stripRepeatingSeparators(newText);
    oldText = _stripRepeatingSeparators(oldText);
    var usesCommaForMantissa = _usesCommasForMantissa();
    if (usesCommaForMantissa) {
      newText = _swapCommasAndPeriods(newText);
      oldText = _swapCommasAndPeriods(oldText);
      oldValue = oldValue.copyWith(text: oldText);
      newValue = newValue.copyWith(text: newText);
    }
    var usesSpacesAsThousandSeparator = _usesSpacesForThousands();
    if (usesSpacesAsThousandSeparator) {
      /// if spaces are used as thousand separators
      /// they must be replaced with commas here
      /// this is used to simplify value processing further
      newText = _replaceSpacesWithCommas(newText);
      oldText = _replaceSpacesWithCommas(oldText);
      oldValue = oldValue.copyWith(text: oldText);
      newValue = newValue.copyWith(text: newText);
    }
    


    var isErasing = newValue.text.length < oldValue.text.length;

    TextSelection selection;

    /// mantissa must always be a period here because the string at this
    /// point is always formmated using commas as thousand separators
    /// for simplicity
    var mantissaSymbol = '.';
    var leadingZeroWithDot = '${leadingSymbol}0$mantissaSymbol';
    var leadingZeroWithoutDot = '$leadingSymbol$mantissaSymbol';

    if (isErasing) {
      if (newValue.selection.end < leadingLength) {
        selection = TextSelection.collapsed(
          offset: leadingLength,
        );
        return TextEditingValue(
          selection: selection,
          text: _prepareDotsAndCommas(oldText),
        );
      }
    } else {
      if (maxTextLength != null) {
        if (newValue.text.length > maxTextLength!) {
          /// we limit string length but only if it's the whole part
          /// we should allow mantissa editing anyway
          /// so this code restrictss the length only if we edit
          /// the main part
          var lastSeparatorIndex = oldText.lastIndexOf('.');
          var isAfterMantissa = newValue.selection.end > lastSeparatorIndex + 1;

          if (!newValue.text.contains('..')) {
            if (!isAfterMantissa) {
              return oldValue;
            }
          }
        }
      }

      if (oldValue.text.length < 1 && newValue.text.length != 1) {
        if (leadingLength < 1) {
          return newValue;
        }
      }
    }

    if (newText.startsWith(leadingZeroWithoutDot)) {
      newText = newText.replaceFirst(leadingZeroWithoutDot, leadingZeroWithDot);
    }
    _processCallback(newText);

    if (isErasing) {
      /// erases and reformats the whole string
      selection = newValue.selection;

      /// here we always have a fraction part
      var lastSeparatorIndex = oldText.lastIndexOf('.');
      if (selection.end == lastSeparatorIndex) {
        /// if a caret was right after the mantissa separator then
        /// we need to bring it before the separator
        /// instead of erasing it
        selection = TextSelection.collapsed(
          offset: oldValue.selection.extentOffset - 1,
        );
        // print('OLD TEXT $oldText');
        var preparedText = _prepareDotsAndCommas(oldText);
        // print('PREPARED TEXT $preparedText');
        return TextEditingValue(
          selection: selection,
          text: preparedText,
        );
      }

      var isAfterSeparator = lastSeparatorIndex < selection.extentOffset;
      if (isAfterSeparator && lastSeparatorIndex > -1) {
        /// if the erasing started before the separator
        /// allow erasing everything
        return newValue.copyWith(
          text: _prepareDotsAndCommas(newValue.text),
        );
      }
      var numSeparatorsBefore = _countSymbolsInString(
        newText,
        ',',
      );
      newText = toCurrencyString(
        newText,
        mantissaLength: mantissaLength,
        leadingSymbol: leadingSymbol,
        trailingSymbol: trailingSymbol,
        thousandSeparator: ThousandSeparator.Comma,
        useSymbolPadding: useSymbolPadding,
      );
      var numSeparatorsAfter = _countSymbolsInString(
        newText,
        ',',
      );
      var selectionOffset = numSeparatorsAfter - numSeparatorsBefore;
      int offset = selection.extentOffset + selectionOffset;
      if (leadingLength > 0) {
        leadingLength = leadingSymbol.length;
        if (offset < leadingLength) {
          offset += leadingLength;
        }
      }
      selection = TextSelection.collapsed(
        offset: offset,
      );

      if (leadingLength > 0) {
        /// this code removes odd zeroes after a leading symbol
        /// do NOT remove this code
        if (newText.contains(leadingZeroWithDot)) {
          newText = newText.replaceAll(
            leadingZeroWithDot,
            leadingZeroWithoutDot,
          );
          offset -= 1;
          if (offset < leadingLength) {
            offset = leadingLength;
          }
          selection = TextSelection.collapsed(
            offset: offset,
          );
        }
      }
      
      var preparedText = _prepareDotsAndCommas(newText);
      return TextEditingValue(
        selection: selection,
        text: preparedText,
      );
    }

    /// stop isErasing
    bool oldStartsWithLeading = leadingSymbol.isNotEmpty &&
        oldValue.text.startsWith(
          leadingSymbol,
        );

    /// count the number of thousand separators in an old string
    /// then check how many of there are there in the new one and if
    /// the number is different add this number to the selection offset
    var oldSelectionEnd = oldValue.selection.end;
    TextEditingValue value = oldSelectionEnd > -1 ? oldValue : newValue;
    String oldSubstrBeforeSelection = oldSelectionEnd > -1
        ? value.text.substring(0, value.selection.end)
        : '';
    int numThousandSeparatorsInOldSub = _countSymbolsInString(
      oldSubstrBeforeSelection,
      ',',
    );

    var formattedValue = toCurrencyString(
      newText,
      leadingSymbol: leadingSymbol,
      mantissaLength: mantissaLength,

      /// we always need a comma here because
      /// this value is not final. The correct symbol will be
      /// added in _prepareDotsAndCommas() method
      thousandSeparator: ThousandSeparator.Comma,
      trailingSymbol: trailingSymbol,
      useSymbolPadding: useSymbolPadding,
    );
    print(formattedValue);

    String newSubstrBeforeSelection = oldSelectionEnd > -1
        ? formattedValue.substring(
            0,
            value.selection.end,
          )
        : '';
    int numThousandSeparatorsInNewSub = _countSymbolsInString(
      newSubstrBeforeSelection,
      ',',
    );

    int numAddedSeparators =
        numThousandSeparatorsInNewSub - numThousandSeparatorsInOldSub;

    bool newStartsWithLeading = leadingSymbol.isNotEmpty &&
        formattedValue.startsWith(
          leadingSymbol,
        );

    /// if an old string did not contain a leading symbol but
    /// the new one does then wee need to add a length of the leading
    /// to the selection offset
    bool addedLeading = !oldStartsWithLeading && newStartsWithLeading;

    var selectionIndex = value.selection.end + numAddedSeparators;

    int wholePartSubStart = 0;
    if (addedLeading) {
      wholePartSubStart = leadingSymbol.length;
      selectionIndex += leadingSymbol.length;
    }
    var mantissaIndex = formattedValue.indexOf(mantissaSymbol);
    if (mantissaIndex > wholePartSubStart) {
      var wholePartSubstring = formattedValue.substring(
        wholePartSubStart,
        mantissaIndex,
      );
      if (selectionIndex < mantissaIndex) {
        if (wholePartSubstring == '0' ||
            wholePartSubstring == '${leadingSymbol}0') {
          /// if the whole part contains 0 only, then we need
          /// to bring the selection after the
          /// fractional part right away
          selectionIndex += 1;
        }
      }
    }
    selectionIndex += 1;
    if (oldValue.text.isEmpty && useSymbolPadding) {
      /// to skip leading space right after a currency symbol
      selectionIndex += 1;
    }
    var selectionEnd = min(
      selectionIndex,
      formattedValue.length,
    );
    var preparedText = _prepareDotsAndCommas(
      formattedValue,
    );
    return TextEditingValue(
      selection: TextSelection.collapsed(
        offset: selectionEnd,
      ),
      text: preparedText,
    );
  }

  bool isZero(String text) {
    var numeriString = toNumericString(text, allowPeriod: true);
    var value = double.tryParse(numeriString) ?? 0.0;
    return value == 0.0;
  }

  String _stripRepeatingSeparators(String input) {
    return input
        .replaceAll(_repeatingDots, '.')
        .replaceAll(_repeatingCommas, ',')
        .replaceAll(_repeatingSpaces, ' ');
  }

  bool _usesCommasForMantissa() {
    var value = (thousandSeparator == ThousandSeparator.Period ||
        thousandSeparator == ThousandSeparator.SpaceAndCommaMantissa);
    return value;
  }
  bool _usesSpacesForThousands() {
    var value = (thousandSeparator == ThousandSeparator.SpaceAndCommaMantissa ||
        thousandSeparator == ThousandSeparator.SpaceAndPeriodMantissa);
    return value;
  }

  /// used for putting correct commas and dots to a
  /// resulting string, after it has been brought to
  /// default view with commas as thousand separator
  String _prepareDotsAndCommas(String value) {
    var useCommasForMantissa = _usesCommasForMantissa();
    if (useCommasForMantissa) {
      value = _swapCommasAndPeriods(value);
    }
    if (thousandSeparator == ThousandSeparator.SpaceAndCommaMantissa) {
      value = value.replaceAll('.', ' ');
    } else if (thousandSeparator == ThousandSeparator.SpaceAndPeriodMantissa) {
      value = value.replaceAll(',', ' ');
    }
    return value;
  }

  void _processCallback(String value) {
    if (onValueChange != null) {
      var numericValue = toNumericString(value, allowPeriod: true);
      var val = double.tryParse(numericValue) ?? 0.0;
      onValueChange!(val);
    }
  }
}

int _countSymbolsInString(String string, String symbolToCount) {
  var counter = 0;
  for (var i = 0; i < string.length; i++) {
    if (string[i] == symbolToCount) counter++;
  }
  return counter;
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
  String? tSeparator;
  switch (thousandSeparator) {
    case ThousandSeparator.Comma:
      tSeparator = ',';
      break;
    case ThousandSeparator.Period:
      tSeparator = ',';
      swapCommasAndPreriods = true;
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
      break;
  }
  // print(thousandSeparator);
  value = value.replaceAll(_repeatingDots, '.');
  value = toNumericString(value, allowPeriod: mantissaLength > 0);
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


/// in case spaces are used as thousands separators 
/// they must be replaced with commas here to simplify parsing
String _replaceSpacesWithCommas(String value) {
  if (value.length < 2) return value;
  var presplit = value.split('');
  var stringBuffer = StringBuffer();
  for (var i = 0; i < presplit.length; i++) {
    var char = presplit[i];
    if (char == ' ') {
      /// we only need to allow spaces as padding
      /// before and after currency symbol
      if (i != 1 && i != presplit.length -2) {
        stringBuffer.write(',');
      }
      else {
        stringBuffer.write(char);
      }
    }
    else {
      stringBuffer.write(char);
    }
  }
  value = stringBuffer.toString();
  // print('VALL $value');
  return value;
}

String _getRoundedValue(String numericString, double roundTo) {
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
