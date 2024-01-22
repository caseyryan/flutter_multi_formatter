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
  static const String WON_SIGN = '₩';
}

@Deprecated(
  'This formatter will be removed in future versions of the' +
      ' package. Please use CurrencyInputFormatter instead',
)
class MoneyInputFormatter extends TextInputFormatter {
  static final RegExp _wrongLeadingZeroMatcher = RegExp(r'^0\d{1}');

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
  /// must not contain digits, periods, commas and dashes
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

  /// [textEditingValue] is used to change
  /// selection in case there is a wrong leading zero
  String? _removeWrongLeadingZero(
    String value,
    TextEditingValue textEditingValue,
  ) {
    var tempValue = value;
    final leadingTotalLength = _leadingLength + _paddingLength;
    if (leadingTotalLength != 0 && tempValue.length >= leadingTotalLength) {
      final curLeading = tempValue.substring(0, leadingTotalLength);
      tempValue = tempValue.substring(leadingTotalLength);
      final match = _wrongLeadingZeroMatcher.matchAsPrefix(tempValue);
      if (match != null) {
        /// The very process of removing the leading zero
        tempValue = tempValue.substring(1, tempValue.length);
        return '$curLeading$tempValue';
      }
    }

    return null;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_leadingLength > 0 && _trailingLength > 0) {
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

    /// If a value starts with something like 02,000.50$
    /// the zero, obviously, must be removed
    int numZeroesRemovedAtStringStart = 0;
    var newRemoveZeroResult = _removeWrongLeadingZero(
      newText,
      newValue,
    );
    if (newRemoveZeroResult != null) {
      newText = newRemoveZeroResult;
      numZeroesRemovedAtStringStart = 1;
    }

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
      newText = _replaceSpacesByCommas(
        newText,
        leadingLength: _leadingLength,
        trailingLength: _trailingLength,
      );
      oldText = _replaceSpacesByCommas(
        oldText,
        leadingLength: _leadingLength,
        trailingLength: _trailingLength,
      );
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
      if (newValue.selection.end < _leadingLength) {
        selection = TextSelection.collapsed(
          offset: _leadingLength,
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
        if (_leadingLength < 1) {
          return newValue;
        }
      }
    }

    // if (newText.startsWith(leadingZeroWithoutDot)) {
    //   newText = newText.replaceFirst(leadingZeroWithoutDot, leadingZeroWithDot);
    // }
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
      if (thousandSeparator == ThousandSeparator.None) {
        /// in case the separator is None it will lead to the wrong
        /// caret placement. Maybe this is not the best
        /// solution to insert this code here, it's more like a dirty hack
        /// but I haven't had time enough to think on some more sophisticated
        /// architectural approach :D
        numSeparatorsAfter = 0;
      }

      var selectionOffset = numSeparatorsAfter - numSeparatorsBefore;
      int offset = selection.extentOffset + selectionOffset;
      if (_leadingLength > 0) {
        // _leadingLength = leadingSymbol.length;
        if (offset < _leadingLength) {
          offset += _leadingLength;
        }
      }
      selection = TextSelection.collapsed(
        offset: offset,
      );

      if (_leadingLength > 0) {
        /// this code removes odd zeroes after a leading symbol
        /// do NOT remove this code
        if (newText.contains(leadingZeroWithDot)) {
          newText = newText.replaceAll(
            leadingZeroWithDot,
            leadingZeroWithoutDot,
          );
          offset -= 1;
          if (offset < _leadingLength) {
            offset = _leadingLength;
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

    /// This check is necessary because if an input looks like this
    /// $.5, toCurrencyString() method will convert it to
    /// $0.5 and the selection must also be shifted by 1 symbol to the right
    var startsWithOrphanPeriod = numericStringStartsWithOrphanPeriod(newText);
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

    /// this is the correctly formatted value
    /// with commas as thousand separators like $1,500.00. The separator
    /// replacements may occure below
    // print(formattedValue);

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

    if (thousandSeparator == ThousandSeparator.None) {
      /// I really want to believe this :-)
      numThousandSeparatorsInNewSub = 0;
      numAddedSeparators = 0;
    }

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
      wholePartSubStart = _leadingLength;
      selectionIndex += _leadingLength;
    }
    if (startsWithOrphanPeriod) {
      selectionIndex += 1;
    }

    /// The rare case when a string starts with 0 and no
    /// mantissa separator after
    selectionIndex -= numZeroesRemovedAtStringStart;

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

    var preparedText = _prepareDotsAndCommas(
      formattedValue,
    );
    var selectionEnd = min(
      selectionIndex,
      preparedText.length,
    );

    return TextEditingValue(
      selection: TextSelection.collapsed(
        offset: selectionEnd,
      ),
      text: preparedText,
    );
  }

  bool isZero(String text) {
    var numeriString = toNumericString(
      text,
      allowPeriod: true,
    );
    var value = double.tryParse(numeriString) ?? 0.0;
    return value == 0.0;
  }

  /// in case spaces are used as thousands separators
  /// they must be replaced with commas here to simplify parsing
  String _replaceSpacesByCommas(
    String value, {
    required int leadingLength,
    required int trailingLength,
  }) {
    if (value.length < 2) return value;
    var presplit = value.split('');
    var stringBuffer = StringBuffer();
    for (var i = 0; i < presplit.length; i++) {
      var char = presplit[i];
      if (char == ' ') {
        /// we only need to allow spaces as padding
        /// before and after currency symbol
        /// this is used for the cases when we use spaces as thousand separators
        final minAllowedSpacePos = leadingLength;
        final maxAllowSpacePos = presplit.length - (1 + trailingLength);
        if (i != minAllowedSpacePos && i != maxAllowSpacePos) {
          stringBuffer.write(',');
        } else {
          stringBuffer.write(char);
        }
      } else {
        stringBuffer.write(char);
      }
    }
    value = stringBuffer.toString();
    // print('VALL $value');
    return value;
  }

  int get _paddingLength {
    return useSymbolPadding ? 1 : 0;
  }

  int get _leadingLength => leadingSymbol.length;
  int get _trailingLength => trailingSymbol.length;

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
    } else if (thousandSeparator == ThousandSeparator.None) {
      value = value.replaceAll(',', '');
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

String _swapCommasAndPeriods(String input) {
  var temp = input;
  if (temp.indexOf('.,') > -1) {
    temp = temp.replaceAll('.,', ',,');
  }
  temp = temp.replaceAll('.', 'PERIOD').replaceAll(',', 'COMMA');
  temp = temp.replaceAll('PERIOD', ',').replaceAll('COMMA', '.');
  return temp;
}

int _countSymbolsInString(String string, String symbolToCount) {
  var counter = 0;
  for (var i = 0; i < string.length; i++) {
    if (string[i] == symbolToCount) counter++;
  }
  return counter;
}
