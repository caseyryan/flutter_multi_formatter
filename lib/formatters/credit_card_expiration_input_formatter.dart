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

import 'formatter_utils.dart';
import 'masked_input_formatter.dart';

class CreditCardExpirationDateFormatter extends MaskedInputFormatter {
  CreditCardExpirationDateFormatter() : super('00/00');

  @override
  FormattedValue applyMask(String text) {
    var fv = super.applyMask(text);
    var result = fv.toString();
    var numericString = toNumericString(
      result,
      allowAllZeroes: true,
    );
    var numAddedLeadingSymbols = 0;
    String? amendedMonth;
    if (numericString.length > 0) {
      var allDigits = numericString.split('');
      var stringBuffer = StringBuffer();
      var firstDigit = int.parse(allDigits[0]);

      if (firstDigit > 1) {
        stringBuffer.write('0');
        stringBuffer.write(firstDigit);
        amendedMonth = stringBuffer.toString();
        numAddedLeadingSymbols = 1;
      } else if (firstDigit == 1) {
        if (allDigits.length > 1) {
          stringBuffer.write(firstDigit);
          var secondDigit = int.parse(allDigits[1]);
          if (secondDigit > 2) {
            stringBuffer.write(2);
          } else {
            stringBuffer.write(secondDigit);
          }
          amendedMonth = stringBuffer.toString();
        }
      }
    }
    if (amendedMonth != null) {
      if (result.length < amendedMonth.length) {
        result = amendedMonth;
      } else {
        var sub = result.substring(2, result.length);
        result = '$amendedMonth$sub';
      }
    }
    fv = super.applyMask(result);

    /// a little hack to be able to move caret by one
    /// symbol to the right if a leading zero was added automatically
    for (var i = 0; i < numAddedLeadingSymbols; i++) {
      fv.increaseNumberOfLeadingSymbols();
    }
    return fv;
  }
}
