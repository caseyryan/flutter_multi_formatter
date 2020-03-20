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

class MoneyInputFormatter extends TextInputFormatter {

  static const String DOLLAR_SIGN = '\$';
  static const String EURO_SIGN = '€';
  static const String POUND_SIGN = '£';
  static const String YEN_SIGN = '￥';


  final ThousandSeparator thousandSeparator;
  final int mantissaLength;
  final String leadingSymbol;
  final String trailingSymbol;
  final bool useSymbolPadding;
  final ValueChanged<double> onValueChange;

  /// [thousandSeparator] specifies what symbol will be used to separate
  /// each block of 3 digits, e.g. [ThousandSeparator.Comma] will format
  /// million as 1,000,000
  /// [ShorteningPolicy.NoShortening] displays a value of 1234456789.34 as 1,234,456,789.34
  /// but [ShorteningPolicy.RoundToThousands] displays the same value as 1,234,456K
  /// [mantissaLength] specifies how many digits will be added after a period sign
  /// [leadingSymbol] any symbol (except for the ones that contain digits) the will be 
  /// added in front of the resulting string. E.g. $ or €
  /// some of the signs are available via constants like [MoneyInputFormatter.EURO_SIGN]
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
    this.onValueChange
  }) : 
    assert(trailingSymbol != null),
    assert(leadingSymbol != null),
    assert(mantissaLength != null),
    assert(thousandSeparator != null),
    assert(useSymbolPadding != null);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    _processCallback(newValue.text);
    var isErasing = newValue.text.length < oldValue.text.length;
    if (isErasing) {
      return newValue;
    } 

    var numPeriods = _countSymbolsInString(newValue.text, '.');
    if (numPeriods > 1) {
      var newSelectionIndex = newValue.selection.end;
      var oldPeriodIndex = oldValue.text.indexOf('.');
      if (newSelectionIndex - oldPeriodIndex != 1) {
        // этот хак позволит переключиться за точку, если 2 точки рядом
        // но не даст ввести еще одну точку, если между ними есть другой символ
        return oldValue;
      }
    }
    
    var fractionLength = mantissaLength;
    var trailingLength = trailingSymbol.length;
    if (useSymbolPadding) {
      if (trailingSymbol.isNotEmpty) {
        trailingLength += 1;
      } 
    }
    fractionLength += trailingLength;

    var formattedValue = toCurrencyString(
      newValue.text, 
      mantissaLength: mantissaLength,
      thousandSeparator: thousandSeparator,
      leadingSymbol: leadingSymbol,
      trailingSymbol: trailingSymbol,
      useSymbolPadding: useSymbolPadding
    );

    var lastDotIndex = formattedValue.lastIndexOf('.');
    // если в строке уже есть точка, либо если выделение справа от точки
    // начинаем редактировать дробную часть заменой символов и смещением вправо
    var moveSelection = formattedValue == oldValue.text || 
        (lastDotIndex > -1 && newValue.selection.end > lastDotIndex);
    var endOffset = max(oldValue.text.length - oldValue.selection.end, 0);
    var numTrailingZeroes = _countTrailingZeroes(formattedValue, trailingSymbolLength: trailingLength);
    var selectionEnd = formattedValue.length - endOffset;
    // проверяет чтобы курсор выделения не находился внутри дробной части
    bool notInMantissaPart = numTrailingZeroes == fractionLength && endOffset <= fractionLength;

    if (notInMantissaPart) {
      if (fractionLength > 0) {
        // если автоматически добавилась дробная часть, когда ее еще не было 
        var addedMoreSymbols = formattedValue.length - oldValue.text.length > 1;
        // +1 чтобы учесть точку
        selectionEnd -= (fractionLength + 1);
        if (addedMoreSymbols) {
          // случай, если дробная часть добавилась, но выделение было не в конце строки
          // (а перед трейлинг символом или его пробелом), нужно сдвинуть выделение так
          // чтобы оно было ровно перед точкой дробной части
          var selectionCompensation = oldValue.text.length - oldValue.selection.end;
          selectionEnd += selectionCompensation;
        }
      }
    } else {
      // переключиться за точку
      if (moveSelection) {
        if (selectionEnd + 1 <= formattedValue.length - trailingLength) {
          selectionEnd += 1;
        } 
      } else {
        var value = double.tryParse(toNumericString(formattedValue, allowPeriod: true)) ?? 0.0;
        if (value == 0.0 && formattedValue.length > fractionLength) {
          // если ввели первый 0, то строка автоматом становится $0.00 и надо поставить
          // выделение сразу после точки и начать правку мантсисы
          selectionEnd = formattedValue.length - fractionLength;
        } else {
          selectionEnd = oldValue.selection.end + (formattedValue.length - oldValue.text.length);
        }
      }
    }
    return TextEditingValue(
      selection: TextSelection.collapsed(offset: min(selectionEnd, formattedValue.length)),
      text: formattedValue
    );
  }

  void _processCallback(String value) {
    if (onValueChange != null) {
      onValueChange(double.tryParse(toNumericString(value, allowPeriod: true)) ?? 0.0);
    }
  }
}

/// нужно только если есть дробная часть
/// чтобы поставить выделение в нужное место
int _countTrailingZeroes(String value, {int trailingSymbolLength = 0}) {
  if (!value.contains('.')) return 0;
  if (value.length <= trailingSymbolLength) return 0;
  var i = value.length - trailingSymbolLength;
  var counter = 0;
  while (i-- > 0) {
    var lastChar = value[i];
    if (isDigit(lastChar)) {
      if (lastChar == '0') {
        counter++;
      } else {
        break;
      }
    }
  }
  return counter + trailingSymbolLength;
}
int _countSymbolsInString(String string, String symbolToCount) {
  var counter = 0;
  for (var i = 0; i < string.length; i++) {
    if (string[i] == symbolToCount) counter++;
  }
  return counter;
}

RegExp _multiPeriodRegExp = RegExp(r'\.+');

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
/// some of the signs are available via constants like [MoneyInputFormatter.EURO_SIGN]
/// but you can basically add any string instead of it. The main rule is that the string 
/// must not contain digits, preiods, commas and dashes
/// [trailingSymbol] is the same as leading but this symbol will be added at the 
/// end of your resulting string like 1,250€ instead of €1,250
/// [useSymbolPadding] adds a space between the number and trailing / leading symbols
/// like 1,250€ -> 1,250 € or €1,250€ -> € 1,250
String toCurrencyString(String value, {
    int mantissaLength = 2,
    ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
    ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
    String leadingSymbol = '',
    String trailingSymbol = '',
    bool useSymbolPadding = false
  }) {

  assert(value != null);
  assert(leadingSymbol != null);
  assert(trailingSymbol != null);
  assert(useSymbolPadding != null);
  assert(shorteningPolicy != null);
  assert(thousandSeparator != null);
  assert(mantissaLength != null);

  String tSeparator;
  switch (thousandSeparator) {
    case ThousandSeparator.Comma:
      tSeparator = ',';
      break;
    case ThousandSeparator.None:
      tSeparator = '';
      break;
    case ThousandSeparator.Space:
      tSeparator = ' ';
      break;
  }
  value = value.replaceAll(_multiPeriodRegExp, '.');
  value = toNumericString(value, allowPeriod: mantissaLength > 0);
  var isNegative = value.contains('-');
  // парсинг нужен, чтобы избежать лишних 
  // символов внутри числа типа -- или множества точек
  var parsed = (double.tryParse(value) ?? 0.0);
  if (parsed == 0.0) {
    if (isNegative) {
      var containsMinus = parsed.toString().contains('-');
      // print('CONTAINS MINUS $containsMinus');
      // parsed = parsed.abs();
      if (!containsMinus) {
        value = '-${parsed.toStringAsFixed(mantissaLength).replaceFirst('0.', '.')}';
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
      // тут просто по длине строки определяет какое сокращение использовать
      var intValStr = (int.tryParse(value) ?? 0).toString();
      if (intValStr.length < 7) {
        minShorteningLength = 4;
        value = '${_getRoundedValue(value, 1000)}K';
      } 
      else if (intValStr.length < 10) {
        minShorteningLength = 7;
        value = '${_getRoundedValue(value, 1000000)}M';
      }
      else if (intValStr.length < 13) {
        minShorteningLength = 10;
        value = '${_getRoundedValue(value, 1000000000)}B';
      }
      else {
        minShorteningLength = 13;
        value = '${_getRoundedValue(value, 1000000000000)}T';
      }
      break;
  }
  var list = <String>[];
  var mantissa = '';
  var split = value.split('');
  var mantissaList = <String>[];
  var periodIndex = value.indexOf('.');
  if (periodIndex > -1) {
    var start = periodIndex + 1;
    var end = start + mantissaLength;
    for (var i = start; i < end; i++) {
      if (i < split.length) {
        mantissaList.add(split[i]);
      } else {
        mantissaList.add('0');
      }
    }
  }

  mantissa = noShortening ? _postProcessMantissa(
    mantissaList.join(''), mantissaLength
  ) : '';
  var maxIndex = split.length - 1;
  if (periodIndex > 0 && noShortening) {
    maxIndex = periodIndex - 1;
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
          if (digitCounter % 3 == 1 && digitCounter > 1 && i > (isNegative ? 1 : 0)) {
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
  return result;
}
String _getRoundedValue(String numericString, double roundTo) {
    assert(roundTo != null && roundTo != 0.0);
    assert(numericString != null);
  var numericValue = double.tryParse(numericString) ?? 0.0;
  var result = numericValue / roundTo;
  // например для 1700, при округлении до 1000 надо вернуть 1.7, а не 1
  var remainder = result.remainder(1.0);
  String prepared;
  if (remainder != 0.0) {
    prepared = result.toStringAsFixed(2);
    if (prepared[prepared.length -1] == '0') {
      prepared = prepared.substring(0, prepared.length - 1);
    }
    return prepared;
  } 
  return result.toInt().toString();
}

/// просто добавляет точку к существующей дробной части
/// либо создает пустую дробную часть, если она не заполнена, но указан длина
String _postProcessMantissa(String mantissaValue, int mantissaLength) {
  if (mantissaLength < 1) return '';
  if (mantissaValue.isNotEmpty) return '.$mantissaValue';
  return '.${List.filled(mantissaLength, '0').join('')}';
}
