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

    return newValue;
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