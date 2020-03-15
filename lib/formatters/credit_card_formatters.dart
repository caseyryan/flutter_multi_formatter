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
import 'masked_input_formatter.dart';

class CreditCardNumberFormatter extends MaskedInputFormater {
  CreditCardNumberFormatter() : super('0000 0000 0000 0000');
}
class CvvCodeFormatter extends MaskedInputFormater {
  CvvCodeFormatter() : super('000');
}

class CreditCardExpirationDateFormatter extends MaskedInputFormater {
  CreditCardExpirationDateFormatter() : super('00/00');

  @override 
  String applyMask(String text) {
    var result = super.applyMask(text);
    var numericString = toNumericString(result);
    String ammendedMonth;
    if (numericString.length > 0) {
      var allDigits = numericString.split('');
      var stringBuffer = StringBuffer();
      var firstDigit = int.parse(allDigits[0]);
      if (firstDigit > 1) {
        stringBuffer.write('0');
        stringBuffer.write(firstDigit);
        ammendedMonth = stringBuffer.toString();
      } 
      else if (firstDigit == 1) {
        if (allDigits.length > 1) {
          stringBuffer.write(firstDigit);
          var secondDigit = int.parse(allDigits[1]);
          if (secondDigit > 2) {
            stringBuffer.write(2);
          } else {
            stringBuffer.write(secondDigit);
          }
          ammendedMonth = stringBuffer.toString();
        }
      }
    }
    if (ammendedMonth != null) {
      if (result.length < ammendedMonth.length) {
        result = ammendedMonth;
      } else {
        var sub = result.substring(2, result.length);
        result = '$ammendedMonth$sub';
      }
    }
    return result;
  }
}

/// allows only latin characters and converts them to uppercase
/// you can use TextCapitalization.characters instead of this formatter 
/// in most cases
class CreditCardHolderNameFormatter extends TextInputFormatter {

  static RegExp _nameMatcher = RegExp(r'[A-Z ]+');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var isErasing = newValue.text.length < oldValue.text.length;
    if (isErasing) {
      return newValue;
    } 
    var newText = newValue.text.toUpperCase();
    var text = newText.split('')
      .where((s) => _nameMatcher.hasMatch(s))
      .map((s) => s.toUpperCase())
      .join('');
    var endOffset = max(oldValue.text.length - oldValue.selection.end, 0);
    var selectionEnd = text.length - endOffset;
    
    return TextEditingValue(
      composing: TextRange.collapsed(selectionEnd),
      selection: TextSelection.collapsed(
        offset: selectionEnd, 
        affinity: TextAffinity.downstream
      ),
      text: text,
    );
  }
  
}