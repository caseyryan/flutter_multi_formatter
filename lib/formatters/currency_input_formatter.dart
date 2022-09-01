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

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

final RegExp _mantissaSeparatorRegexp = RegExp(r'[,.]');
final RegExp _illegalCharsRegexp = RegExp(r'[^0-9-,.]+');
final RegExp _illegalLeadingOrTrailing = RegExp(r'[-,.+]+');

class CurrencySymbols {
  static const String DOLLAR_SIGN = '\$';
  static const String EURO_SIGN = '€';
  static const String POUND_SIGN = '£';
  static const String YEN_SIGN = '￥';
  static const String ETHERIUM_SIGN = 'Ξ';
  static const String BITCOIN_SIGN = 'Ƀ';
  static const String SWISS_FRANK_SIGN = '₣';
  static const String RUBLE_SIGN = '₽';
}

class CurrencyInputFormatter extends TextInputFormatter {
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
  /// some of the signs are available via constants like [CurrencySymbols.EURO_SIGN]
  /// but you can basically add any string instead of it. The main rule is that the string
  /// must not contain digits, preiods, commas and dashes
  /// [trailingSymbol] is the same as leading but this symbol will be added at the
  /// end of your resulting string like 1,250€ instead of €1,250
  /// [useSymbolPadding] adds a space between the number and trailing / leading symbols
  /// like 1,250€ -> 1,250 € or €1,250€ -> € 1,250
  /// [onValueChange] a callback that will be called on a number change
  CurrencyInputFormatter({
    this.thousandSeparator = ThousandSeparator.Comma,
    this.mantissaLength = 2,
    this.leadingSymbol = '',
    this.trailingSymbol = '',
    this.useSymbolPadding = false,
    this.onValueChange,
    this.maxTextLength,
  }) : assert(
            !leadingSymbol.contains(_illegalLeadingOrTrailing) &&
                !trailingSymbol.contains(_illegalLeadingOrTrailing),
            '''
    Illegal trailing or reading symbol. You cannot use 
    the next symbols as leading or trailing because 
    they might interfere with numbers: -,.+
  ''');

  String get _mantissaSeparator {
    if (thousandSeparator == ThousandSeparator.Period ||
        thousandSeparator == ThousandSeparator.SpaceAndCommaMantissa) {
      return ',';
    }
    return '.';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trailingLength = _getTrailingLength();
    final leadingLength = _getLeadingLength();
    final oldCaretIndex = max(oldValue.selection.start, oldValue.selection.end);
    final newCaretIndex = max(newValue.selection.start, newValue.selection.end);
    var newText = newValue.text;

    final newAsNumeric = toNumericString(
      newText,
      allowPeriod: true,
      mantissaSeparator: _mantissaSeparator,
    );

    var oldText = oldValue.text;
    if (oldValue == newValue) {
      return newValue;
    }
    bool isErasing = newText.length < oldText.length;
    if (isErasing) {
      if (mantissaLength == 0 && oldCaretIndex == oldValue.text.length) {
        return oldValue.copyWith(
            selection: TextSelection.collapsed(
                offset: oldCaretIndex - trailingLength));
      }
      if (_hasErasedMantissaSeparator(
        shorterString: newText,
        longerString: oldText,
      )) {
        return oldValue.copyWith(
          selection: TextSelection.collapsed(
            offset: oldCaretIndex - 1,
          ),
        );
      }
    } else {
      if (_containsIllegalChars(newText)) {
        return oldValue;
      }
    }

    int afterMantissaPosition = _countAfterMantissaPosition(
      oldText: oldText,
      oldCaretOffset: oldCaretIndex,
    );

    final newAsCurrency = toCurrencyString(
      newText,
      mantissaLength: mantissaLength,
      thousandSeparator: thousandSeparator,
      leadingSymbol: leadingSymbol,
      trailingSymbol: trailingSymbol,
      useSymbolPadding: useSymbolPadding,
    );

    if (_switchToRightInWholePart(
      newText: newText,
      oldText: oldText,
    )) {
      // print('RETURN 4 ${oldValue.text}');
      return oldValue.copyWith(
        selection: TextSelection.collapsed(
          offset: oldCaretIndex + 1,
        ),
      );
    }

    if (afterMantissaPosition > 0) {
      if (_switchToLeftInMantissa(
        newText: newText,
        oldText: oldText,
        caretPosition: newCaretIndex,
      )) {
        // print('RETURN 5 $newAsCurrency');
        return TextEditingValue(
          selection: TextSelection.collapsed(
            offset: newCaretIndex,
          ),
          text: newAsCurrency,
        );
      } else {
        // print('RETURN 6 $newAsCurrency');
        int offset = min(
          newCaretIndex,
          newAsCurrency.length - trailingLength,
        );
        return TextEditingValue(
          selection: TextSelection.collapsed(
            offset: offset,
          ),
          text: newAsCurrency,
        );
      }
    }

    var initialCaretOffset = leadingLength;
    if (_isZeroOrEmpty(newAsNumeric)) {
      // print('RETURN 7 ${newValue.text}');
      return newValue.copyWith(
        text: newAsCurrency,
        selection: TextSelection.collapsed(
          offset: initialCaretOffset + 1,
        ),
      );
    }
    final oldAsCurrency = toCurrencyString(
      oldText,
      mantissaLength: mantissaLength,
      thousandSeparator: thousandSeparator,
      leadingSymbol: leadingSymbol,
      trailingSymbol: trailingSymbol,
      useSymbolPadding: useSymbolPadding,
    );

    var lengthDiff = newAsCurrency.length - oldAsCurrency.length;

    initialCaretOffset = max(
      (oldCaretIndex + lengthDiff),
      leadingLength + 1,
    );

    if (initialCaretOffset < 1) {
      if (newAsCurrency.isNotEmpty) {
        initialCaretOffset += 1;
      }
    }
    // print('RETURN 8 $newAsCurrency');
    return TextEditingValue(
      selection: TextSelection.collapsed(
        offset: initialCaretOffset,
      ),
      text: newAsCurrency,
    );
  }

  bool _isZeroOrEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return true;
    }
    value = toNumericString(
      value,
      allowPeriod: true,
      mantissaSeparator: _mantissaSeparator,
    );
    try {
      return double.parse(value) == 0.0;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return false;
  }

  int _getLeadingLength() {
    if (useSymbolPadding) {
      if (leadingSymbol.length > 0) {
        return leadingSymbol.length + 1;
      } else {
        return 0;
      }
    }
    return leadingSymbol.length;
  }

  int _getTrailingLength() {
    if (useSymbolPadding) {
      if (trailingSymbol.length > 0) {
        return trailingSymbol.length + 1;
      } else {
        return 0;
      }
    }
    return trailingSymbol.length;
  }

  List<String> _findDifferentChars({
    required String longerString,
    required String shorterString,
  }) {
    final newChars = longerString.split('');
    final oldChars = shorterString.split('');
    for (var i = 0; i < oldChars.length; i++) {
      final oldChar = oldChars[i];
      newChars.remove(oldChar);
    }
    return newChars;
  }

  bool _containsMantissaSeparator(List<String> chars) {
    for (var char in chars) {
      if (char == _mantissaSeparator) {
        return true;
      }
    }
    return false;
  }

  bool _switchToRightInWholePart({
    required String newText,
    required String oldText,
  }) {
    if (newText.length > oldText.length) {
      final newChars = _findDifferentChars(
        longerString: newText,
        shorterString: oldText,
      );
      if (_containsMantissaSeparator(newChars)) {
        return true;
      }
    }
    return false;
  }

  bool _switchToLeftInMantissa({
    required String newText,
    required String oldText,
    required int caretPosition,
  }) {
    if (newText.length < oldText.length) {
      if (caretPosition < newText.length) {
        var nextChar = '';
        if (caretPosition < newText.length - 1) {
          nextChar = newText[caretPosition];
          if (!isDigit(nextChar, positiveOnly: true) ||
              int.tryParse(nextChar) == 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  int _countAfterMantissaPosition({
    required String oldText,
    required int oldCaretOffset,
  }) {
    if (mantissaLength < 1) {
      return 0;
    }
    final mantissaIndex = oldText.lastIndexOf(
      _mantissaSeparatorRegexp,
    );
    if (mantissaIndex < 0) {
      return 0;
    }
    if (oldCaretOffset > mantissaIndex) {
      return oldCaretOffset - mantissaIndex;
    }
    return 0;
  }

  bool _hasErasedMantissaSeparator({
    required String shorterString,
    required String longerString,
  }) {
    final differentChars = _findDifferentChars(
      shorterString: shorterString,
      longerString: longerString,
    );
    if (_containsMantissaSeparator(differentChars)) {
      return true;
    }
    return false;
  }

  bool _containsIllegalChars(String input) {
    if (input.isEmpty) return false;
    var clearedInput = input;
    if (leadingSymbol.isNotEmpty) {
      clearedInput = clearedInput.replaceAll(leadingSymbol, '');
    }
    if (trailingSymbol.isNotEmpty) {
      clearedInput = clearedInput.replaceAll(trailingSymbol, '');
    }
    clearedInput = clearedInput.replaceAll(' ', '');
    return _illegalCharsRegexp.hasMatch(clearedInput);
  }
}
