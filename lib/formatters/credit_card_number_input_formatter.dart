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
import 'package:flutter_multi_formatter/utils/luhn_algo.dart';

import 'formatter_utils.dart';

class CardSystem {
  static const String MIR = 'MIR';
  static const String UNION_PAY = 'UnionPay';
  static const String VISA = 'Visa';
  static const String MASTERCARD = 'Mastercard';
  static const String JCB = 'JCB';
  static const String DISCOVER = 'Discover';
  static const String MAESTRO = 'Maestro';
  static const String AMERICAN_EXPRESS = 'Amex';
  static const String DINERS_CLUB = 'DinersClub';
  static const String UZ_CARD = 'UzCard';
  static const String HUMO = 'HUMO';
}

class CreditCardNumberInputFormatter extends TextInputFormatter {
  final ValueChanged<CardSystemData?>? onCardSystemSelected;
  final bool useSeparators;

  CardSystemData? _cardSystemData;
  CreditCardNumberInputFormatter({
    this.onCardSystemSelected,
    this.useSeparators = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var isErasing = newValue.text.length < oldValue.text.length;
    if (isErasing) {
      if (newValue.text.isEmpty) {
        _removeFirstLetter();
      }
    }
    var onlyNumbers = toNumericString(
      newValue.text,
    );
    String maskedValue = _applyMask(
      onlyNumbers,
    );
    if (maskedValue.length == oldValue.text.length) {
      return oldValue;
    }
    var endOffset = max(
      oldValue.text.length - oldValue.selection.end,
      0,
    );
    var selectionEnd = maskedValue.length - endOffset;
    return TextEditingValue(
      selection: TextSelection.collapsed(
        offset: selectionEnd,
      ),
      text: maskedValue,
    );
  }

  /// this is a small dirty hack to be able to remove the first character
  Future _removeFirstLetter() async {
    await Future.delayed(
      Duration(
        milliseconds: 5,
      ),
    );
    _updateCardSystemData(null);
  }

  void _updateCardSystemData(
    CardSystemData? cardSystemData,
  ) {
    _cardSystemData = cardSystemData;
    if (onCardSystemSelected != null) {
      onCardSystemSelected!(_cardSystemData);
    }
  }

  String _applyMask(
    String numericString,
  ) {
    if (numericString.isEmpty) {
      _updateCardSystemData(null);
    } else {
      var countryData = _CardSystemDatas.getCardSystemDataByNumber(
        numericString,
      );
      if (countryData != null) {
        _updateCardSystemData(
          countryData,
        );
      }
    }
    if (_cardSystemData != null) {
      return _formatByMask(numericString, _cardSystemData!.numberMask!);
    }
    return numericString;
  }
}

/// [useLuhnAlgo] validates the number using the Luhn algorithm
bool isCardNumberValid({
  required String cardNumber,
  bool checkLength = false,
  bool useLuhnAlgo = true,
}) {
  cardNumber = toNumericString(
    cardNumber,
    allowAllZeroes: true,
    allowHyphen: false,
    allowPeriod: false,
  );
  if (cardNumber.isEmpty) {
    return false;
  }
  var countryData = _CardSystemDatas.getCardSystemDataByNumber(cardNumber);
  if (countryData == null) {
    return false;
  }
  if (useLuhnAlgo) {
    final isLuhnOk = checkNumberByLuhn(number: cardNumber);
    if (!isLuhnOk) {
      return false;
    }
  }
  var formatted = _formatByMask(cardNumber, countryData.numberMask!);
  var reprocessed = toNumericString(formatted);
  return reprocessed == cardNumber &&
      (checkLength == false || reprocessed.length == countryData.numDigits);
}

/// checks not only for a length and characters but also
/// for card system code. If it's not found the succession of numbers
/// will not be marked as a valid card number
@Deprecated('Use isCardNumberValid() instead')
bool isCardValidNumber(
  String cardNumber, {
  bool checkLength = false,
}) {
  return isCardNumberValid(
    cardNumber: cardNumber,
    checkLength: checkLength,
    useLuhnAlgo: false,
  );
}

String formatAsCardNumber(String cardNumber) {
  if (!isCardNumberValid(
    cardNumber: cardNumber,
  )) {
    return _formatByMask(cardNumber, '0000 0000 0000 0000');
  }
  cardNumber = toNumericString(
    cardNumber,
  );
  var cardSystemData = _CardSystemDatas.getCardSystemDataByNumber(cardNumber)!;
  return _formatByMask(cardNumber, cardSystemData.numberMask!);
}

CardSystemData? getCardSystemData(
  String cardNumber,
) {
  return _CardSystemDatas.getCardSystemDataByNumber(cardNumber);
}

String _formatByMask(
  String text,
  String mask,
) {
  var chars = text.split('');
  var result = <String>[];
  var index = 0;
  for (var i = 0; i < mask.length; i++) {
    if (index >= chars.length) {
      break;
    }
    var curChar = chars[index];
    if (mask[i] == '0') {
      if (isDigit(curChar)) {
        result.add(curChar);
        index++;
      } else {
        break;
      }
    } else {
      result.add(mask[i]);
    }
  }
  return result.join();
}

class CardSystemData {
  final String? system;
  final String? systemCode;
  final String? numberMask;
  final int? numDigits;

  CardSystemData._init({
    this.numberMask,
    this.system,
    this.systemCode,
    this.numDigits,
  });

  factory CardSystemData.fromMap(Map value) {
    return CardSystemData._init(
      system: value['system'],
      systemCode: value['systemCode'],
      numDigits: value['numDigits'],
      numberMask: value['numberMask'],
    );
  }
  @override
  String toString() {
    return '[CardSystemData(system: $system,' + ' systemCode: $systemCode]';
  }
}

class _CardSystemDatas {
  static CardSystemData? getCardSystemDataByNumber(
    String cardNumber, {
    int? substringLength,
  }) {
    if (cardNumber.isEmpty) return null;
    substringLength = substringLength ?? cardNumber.length;

    if (substringLength < 1) return null;
    Map? rawData;
    List<Map> tempSystems = [];
    for (var data in _data) {
      final systemCode = data['systemCode'];
      if (cardNumber.startsWith(systemCode)) {
        tempSystems.add(data);
      }
    }
    if (tempSystems.isEmpty) {
      return null;
    }
    if (tempSystems.length == 1) {
      rawData = tempSystems.first;
    } else {
      tempSystems.sort((a, b) => b['systemCode'].compareTo(a['systemCode']));
      final int maxCodeLength = tempSystems.first['systemCode'].length;
      tempSystems = tempSystems
          .where(
            (e) => e['systemCode'].length == maxCodeLength,
          )
          .toList();

      tempSystems.sort((a, b) => a['systemCode'].compareTo(b['systemCode']));
      for (var data in tempSystems) {
        final int numMaskDigits = data['numDigits']!;
        if (cardNumber.length <= numMaskDigits) {
          rawData = data;
          break;
        }
      }
      if (rawData == null) {
        rawData = tempSystems.last;
      }
    }
    return CardSystemData.fromMap(rawData);
  }

  static List<Map<String, dynamic>> _data = <Map<String, dynamic>>[
    {
      'system': CardSystem.VISA,
      'systemCode': '4',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.DINERS_CLUB,
      'systemCode': '14',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.DINERS_CLUB,
      'systemCode': '36',
      'numberMask': '0000 000000 0000',
      'numDigits': 14,
    },
    {
      'system': CardSystem.DINERS_CLUB,
      'systemCode': '54',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.DINERS_CLUB,
      'systemCode': '30',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.MASTERCARD,
      'systemCode': '5',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.MASTERCARD,
      'systemCode': '222',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.MASTERCARD,
      'systemCode': '2720',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.AMERICAN_EXPRESS,
      'systemCode': '34',
      'numberMask': '0000 000000 00000',
      'numDigits': 15,
    },
    {
      'system': CardSystem.AMERICAN_EXPRESS,
      'systemCode': '37',
      'numberMask': '0000 000000 00000',
      'numDigits': 15,
    },
    {
      'system': CardSystem.JCB,
      'systemCode': '35',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.UZ_CARD,
      'systemCode': '8600',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.UZ_CARD,
      'systemCode': '5614',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.HUMO,
      'systemCode': '9860',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.DISCOVER,
      'systemCode': '60',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.DISCOVER,
      'systemCode': '60',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 19,
    },
    {
      'system': CardSystem.MAESTRO,
      'systemCode': '67',
      'numberMask': '0000 0000 0000 0000 0',
      'numDigits': 17,
    },
    {
      'system': CardSystem.MAESTRO,
      'systemCode': '67',
      'numberMask': '00000000 0000000000',
      'numDigits': 18,
    },
    {
      'system': CardSystem.MIR,
      'systemCode': '2200',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.MIR,
      'systemCode': '2204',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.UNION_PAY,
      'systemCode': '62',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.UNION_PAY,
      'systemCode': '62',
      'numberMask': '0000 0000 0000 0000 000',
      'numDigits': 19,
    },
  ];
}
