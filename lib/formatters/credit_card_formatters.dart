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