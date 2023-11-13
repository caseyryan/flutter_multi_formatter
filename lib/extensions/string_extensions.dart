import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

extension StringExtension on String {
  String removeCharAt(int charIndex) {
    final charList = split('').toList();
    charList.removeAt(charIndex);
    return charList.join('');
  }

  String toPhoneNumber({
    InvalidPhoneAction invalidPhoneAction = InvalidPhoneAction.ShowUnformatted,
    bool allowEndlessPhone = false,
    String? defaultMask,
    String? defaultCountryCode,
  }) {
    return formatAsPhoneNumber(
          this,
          allowEndlessPhone: allowEndlessPhone,
          defaultCountryCode: defaultCountryCode,
          defaultMask: defaultMask,
          invalidPhoneAction: invalidPhoneAction,
        ) ??
        this;
  }

  String toCardNumber() {
    return formatAsCardNumber(this);
  }

  bool isValidCardNumber({
    bool checkLength = false,
    bool useLuhnAlgo = true,
  }) {
    return isCardNumberValid(
      cardNumber: this,
      useLuhnAlgo: useLuhnAlgo,
      checkLength: checkLength,
    );
  }
}
