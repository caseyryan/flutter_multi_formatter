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
  static const String ETHEREUM_SIGN = 'Ξ';
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
  final ValueChanged<num>? onValueChange;

  bool _printDebugInfo = false;

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
  /// must not contain digits, periods, commas and dashes
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

  void _updateValue(String value) {
    if (onValueChange == null) {
      return;
    }
    _widgetsBinding?.addPostFrameCallback((timeStamp) {
      try {
        if (mantissaLength < 1) {
          onValueChange!(int.tryParse(value) ?? double.nan);
        } else {
          onValueChange!(double.tryParse(value) ?? double.nan);
        }
      } catch (e) {
        onValueChange!(double.nan);
      }
    });
  }

  dynamic get _widgetsBinding {
    return WidgetsBinding.instance;
  }

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
    int oldCaretIndex = max(oldValue.selection.start, oldValue.selection.end);
    int newCaretIndex = max(newValue.selection.start, newValue.selection.end);
    var newText = newValue.text;
    final newAsNumeric = toNumericString(
      newText,
      allowPeriod: true,
      mantissaSeparator: _mantissaSeparator,
      mantissaLength: mantissaLength,
    );
    _updateValue(newAsNumeric);

    var oldText = oldValue.text;
    if (oldValue == newValue) {
      if (_printDebugInfo) {
        print('RETURN 0 ${oldValue.text}');
      }
      return newValue;
    }
    bool isErasing = newText.length < oldText.length;
    if (isErasing) {
      if (mantissaLength == 0 && oldCaretIndex == oldValue.text.length) {
        if (trailingLength > 0) {
          if (_printDebugInfo) {
            print('RETURN 1 ${oldValue.text}');
          }
          return oldValue.copyWith(
            selection: TextSelection.collapsed(
              offset: min(
                oldValue.text.length,
                oldCaretIndex - trailingLength,
              ),
            ),
          );
        }
      } else {
        if (thousandSeparator == ThousandSeparator.Space) {
          /// It's a dirty hack to try and fix this issue
          /// https://github.com/caseyryan/flutter_multi_formatter/issues/145
          /// The problem there is that after erasing just a white space
          /// the number from e.g. this 45 555 $ becomes this 45555 $ but
          /// after applying the format again in regains the lost space and
          /// this leads to a situation when nothing seems to be changed
          final differences = _findDifferentChars(
            longerString: oldText,
            shorterString: newText,
          );
          if (differences.length == 1 && differences.first == ' ') {
            if (newCaretIndex > 0) {
              newCaretIndex = newCaretIndex.subtractClamping(1);
              oldCaretIndex = oldCaretIndex.subtractClamping(1);
              newText = newText.removeCharAt(newCaretIndex);
            }
          }
        }
      }
      if (_hasErasedMantissaSeparator(
        shorterString: newText,
        longerString: oldText,
      )) {
        if (_printDebugInfo) {
          print('RETURN 2 ${oldValue.text}');
        }
        return oldValue.copyWith(
          selection: TextSelection.collapsed(
            offset: min(
              oldValue.text.length,
              oldCaretIndex - 1,
            ),
          ),
        );
      }
    } else {
      if (_containsIllegalChars(newText)) {
        if (_printDebugInfo) {
          print('RETURN 3 ${oldValue.text}');
        }
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
      if (_printDebugInfo) {
        print('RETURN 4 ${oldValue.text.length} $oldCaretIndex');
      }
      return oldValue.copyWith(
        selection: TextSelection.collapsed(
          offset: min(
            oldValue.text.length,
            oldCaretIndex + 1,
          ),
        ),
      );
    }

    if (afterMantissaPosition > 0) {
      if (_switchToLeftInMantissa(
        newText: newText,
        oldText: oldText,
        caretPosition: newCaretIndex,
      )) {
        if (_printDebugInfo) {
          print('RETURN 5 $newAsCurrency');
        }
        return TextEditingValue(
          selection: TextSelection.collapsed(
            offset: newCaretIndex,
          ),
          text: newAsCurrency,
        );
      } else {
        if (_printDebugInfo) {
          print('RETURN 6 $newAsCurrency');
        }
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
      if (_printDebugInfo) {
        print('RETURN 7 ${newValue.text}');
      }
      int offset = min(
        newValue.text.length,
        initialCaretOffset + 1,
      );
      if (newValue.text == '') {
        offset = 1;
      }
      return newValue.copyWith(
        text: newAsCurrency,
        selection: TextSelection.collapsed(
          offset: offset,
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

    if (_printDebugInfo) {
      print('RETURN 8 $newAsCurrency');
    }
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
      mantissaLength: mantissaLength,
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

      /// [hasWrongSeparator] is an attempt to fix this
      /// https://github.com/caseyryan/flutter_multi_formatter/issues/114
      /// Not sure if it will have some side effect
      final hasWrongSeparator =
          newText.contains(',.') || newText.contains('.,');
      if (_containsMantissaSeparator(newChars) || hasWrongSeparator) {
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
      /// allows to get read of an odd minus in front of a leading symbol
      /// https://github.com/caseyryan/flutter_multi_formatter/issues/123
      var sub = clearedInput.substring(
        0,
        clearedInput.indexOf(leadingSymbol) + 1,
      );
      if (sub.length > leadingSymbol.length) {
        return true;
      }
      clearedInput = clearedInput.replaceAll(RegExp('[$leadingSymbol]+'), '');
    }
    if (trailingSymbol.isNotEmpty) {
      clearedInput = clearedInput.replaceAll(RegExp('[$trailingSymbol]+'), '');
    }
    clearedInput = clearedInput.replaceAll(' ', '');
    return _illegalCharsRegexp.hasMatch(clearedInput);
  }
}
