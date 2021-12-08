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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'formatter_utils.dart';
import 'phone_input_enums.dart';

class PhoneInputFormatter extends TextInputFormatter {
  final ValueChanged<PhoneCountryData?>? onCountrySelected;
  final bool allowEndlessPhone;

  PhoneCountryData? _countryData;
  String _lastValue = '';

  /// [onCountrySelected] when you enter a phone
  /// and a country is detected
  /// this callback gets called
  /// [allowEndlessPhone] if true, a phone can
  /// still be enterng after the whole mask is matched.
  /// use if you are not sure that all masks are supported
  PhoneInputFormatter({
    this.onCountrySelected,
    this.allowEndlessPhone = false,
  });

  String get masked => _lastValue;

  String get unmasked => '+${toNumericString(_lastValue, allowHyphen: false)}';

  bool get isFilled => isPhoneValid(masked);

  String mask(String value) {
    return formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: value),
    ).text;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var isErasing = newValue.text.length < oldValue.text.length;
    _lastValue = newValue.text;

    var onlyNumbers = toNumericString(newValue.text);
    String maskedValue;
    if (isErasing) {
      if (newValue.text.isEmpty) {
        _clearCountry();
      }
    }
    if (onlyNumbers.length == 2) {
      /// хак специально для России, со вводом номера с восьмерки
      /// меняем ее на 7
      var isRussianWrongNumber =
          onlyNumbers[0] == '8' && onlyNumbers[1] == '9' ||
              onlyNumbers[0] == '8' && onlyNumbers[1] == '3';
      if (isRussianWrongNumber) {
        onlyNumbers = '7${onlyNumbers[1]}';
        _countryData = null;
        _applyMask(
          '7',
          allowEndlessPhone,
        );
      }
    }

    maskedValue = _applyMask(onlyNumbers, allowEndlessPhone);
    // if (maskedValue.length == oldValue.text.length && onlyNumbers != '7') {
    if (maskedValue == oldValue.text && onlyNumbers != '7') {
      _lastValue = maskedValue;
      if (isErasing) {
        var newSelection = oldValue.selection;
        newSelection = newSelection.copyWith(
          baseOffset: oldValue.selection.baseOffset,
          extentOffset: oldValue.selection.baseOffset,
        );
        return oldValue.copyWith(
          selection: newSelection,
        );
      }
      return oldValue;
    }

    final endOffset = newValue.text.length - newValue.selection.end;
    final selectionEnd = maskedValue.length - endOffset;

    _lastValue = maskedValue;
    return TextEditingValue(
      selection: TextSelection.collapsed(offset: selectionEnd),
      text: maskedValue,
    );
  }

  /// this is a small dirty hask to be able to remove the firt characted
  Future _clearCountry() async {
    await Future.delayed(Duration(milliseconds: 5));
    _updateCountryData(null);
  }

  void _updateCountryData(PhoneCountryData? countryData) {
    _countryData = countryData;
    if (onCountrySelected != null) {
      onCountrySelected!(_countryData);
    }
  }

  String _applyMask(String numericString, bool allowEndlessPhone) {
    if (numericString.isEmpty) {
      _updateCountryData(null);
    } else {
      var countryData = PhoneCodes.getCountryDataByPhone(numericString);
      if (countryData != null) {
        _updateCountryData(countryData);
      }
    }
    if (_countryData != null) {
      return _formatByMask(
        numericString,
        _countryData!.phoneMask!,
        _countryData!.altMasks,
        0,
        allowEndlessPhone,
      );
    }
    return numericString;
  }

  /// adds a list of alternative phone maskes to a country
  /// data. This method can be used if some mask is lacking
  /// [countryCode] must be exactrly 2 uppercase letters like RU, or US
  /// or ES, or DE.
  /// [alternativeMasks] a list of masks like
  /// ['+00 (00) 00000-0000', '+00 (00) 0000-0000'] that will be used
  /// as an alternative. The list might be in any order
  /// [mergeWithExisting] if this is true, new masks will be added to
  /// an existing list. If false, the new list will completely replace the
  /// existing one
  static void addAlternativePhoneMasks({
    required String countryCode,
    required List<String> alternativeMasks,
    bool mergeWithExisting = false,
  }) {
    assert(alternativeMasks.isNotEmpty);
    final countryData = _findCountryDataByCountryCode(countryCode);
    String currentMask = countryData['phoneMask'];
    alternativeMasks.sort((a, b) => a.length.compareTo(b.length));
    countryData['phoneMask'] = alternativeMasks.first;
    alternativeMasks.removeAt(0);
    if (!alternativeMasks.contains(currentMask)) {
      alternativeMasks.add(currentMask);
    }
    alternativeMasks.sort((a, b) => a.length.compareTo(b.length));
    if (!mergeWithExisting || countryData['altMasks'] == null) {
      countryData['altMasks'] = alternativeMasks;
    } else {
      final existingList = countryData['altMasks'];
      alternativeMasks.forEach((m) {
        existingList.add(m);
      });
    }
    print('Alternative masks for country "${countryData['country']}"' +
        ' is now ${countryData['altMasks']}');
  }

  /// Replaces an existing phone mask for the given country
  /// e.g. Russian mask right now is +0 (000) 000-00-00
  /// if you want to replace it by +0 (000) 000 00 00
  /// simply call this method like this
  /// PhoneInputFormatter.replacePhoneMask(
  ///   countryCode: 'RU',
  ///   newMask: '+0 (000) 000 00 00',
  /// );
  static void replacePhoneMask({
    required String countryCode,
    required String newMask,
  }) {
    checkMask(newMask);
    final countryData = _findCountryDataByCountryCode(countryCode);
    var currentMask = countryData['phoneMask'];
    if (currentMask != newMask) {
      print(
        'Phone mask for country "${countryData['country']}"' +
            ' was replaced from $currentMask to $newMask',
      );
      countryData['phoneMask'] = newMask;
    }
  }

  static Map<String, dynamic> _findCountryDataByCountryCode(
    String countryCode,
  ) {
    assert(countryCode.length == 2);
    countryCode = countryCode.toUpperCase();
    var countryData = PhoneCodes._data.firstWhereOrNull(
      ((m) => m!['countryCode'] == countryCode),
    );
    if (countryData == null) {
      throw 'A country with a code of $countryCode is not found';
    }
    return countryData;
  }
}

bool isPhoneValid(
  String phone, {
  bool allowEndlessPhone = false,
}) {
  phone = toNumericString(
    phone,
    allowHyphen: false,
  );
  if (phone.isEmpty) {
    return false;
  }
  var countryData = PhoneCodes.getCountryDataByPhone(
    phone,
  );
  if (countryData == null) {
    return false;
  }
  var formatted = _formatByMask(
    phone,
    countryData.phoneMask!,
    countryData.altMasks,
    0,
    allowEndlessPhone,
  );
  var rpeprocessed = toNumericString(
    formatted,
    allowHyphen: false,
  );
  if (allowEndlessPhone) {
    var contains = phone.contains(rpeprocessed);
    return contains;
  }
  var correctLength = formatted.length == countryData.phoneMask!.length;
  if (correctLength != true && countryData.altMasks != null) {
    return countryData.altMasks!.any(
      (altMask) => formatted.length == altMask.length,
    );
  }
  return correctLength;
}

/// [allowEndlessPhone] if this is true,
/// the
String? formatAsPhoneNumber(
  String phone, {
  InvalidPhoneAction invalidPhoneAction = InvalidPhoneAction.ShowUnformatted,
  bool allowEndlessPhone = false,
  String? defaultMask,
}) {
  if (!isPhoneValid(
    phone,
    allowEndlessPhone: allowEndlessPhone,
  )) {
    switch (invalidPhoneAction) {
      case InvalidPhoneAction.ShowUnformatted:
        if (defaultMask == null) return phone;
        break;
      case InvalidPhoneAction.ReturnNull:
        return null;
      case InvalidPhoneAction.ShowPhoneInvalidString:
        return 'invalid phone';
    }
  }
  phone = toNumericString(phone);
  var countryData = PhoneCodes.getCountryDataByPhone(phone);

  if (countryData != null) {
    return _formatByMask(
      phone,
      countryData.phoneMask!,
      countryData.altMasks,
      0,
      allowEndlessPhone,
    );
  } else {
    return _formatByMask(
      phone,
      defaultMask!,
      null,
      0,
      allowEndlessPhone,
    );
  }
}

String _formatByMask(
  String text,
  String mask,
  List<String>? altMasks, [
  int altMaskIndex = 0,
  bool allowEndlessPhone = false,
]) {
  text = toNumericString(text, allowHyphen: false);
  // print("TEXT $text, MASK $mask");
  var result = <String>[];
  var indexInText = 0;
  for (var i = 0; i < mask.length; i++) {
    if (indexInText >= text.length) {
      break;
    }
    var curMaskChar = mask[i];
    if (curMaskChar == '0') {
      var curChar = text[indexInText];
      if (isDigit(curChar)) {
        result.add(curChar);
        indexInText++;
      } else {
        break;
      }
    } else {
      result.add(curMaskChar);
    }
  }

  var actualDigitsInMask = toNumericString(
    mask,
    allowHyphen: false,
  ).replaceAll(',', '');
  if (actualDigitsInMask.length < text.length) {
    if (altMasks != null && altMaskIndex < altMasks.length) {
      var formatResult = _formatByMask(
        text,
        altMasks[altMaskIndex],
        altMasks,
        altMaskIndex + 1,
        allowEndlessPhone,
      );
      // print('RETURN 1 $formatResult');
      return formatResult;
    }

    if (allowEndlessPhone) {
      /// if you do not need to restrict the length of phones
      /// by a mask
      result.add(' ');
      for (var i = actualDigitsInMask.length; i < text.length; i++) {
        result.add(text[i]);
      }
    }
  }

  final jointResult = result.join();
  // print('RETURN 2 $jointResult');
  return jointResult;
}

/// returns a list of country datas with a country code of
/// the supplied phone number. The return type is List because
/// many countries and territories may share the same phone code
/// the list will contain one [PhoneCountryData] at max
/// [returns] A list of [PhoneCountryData] datas or an empty list
List<PhoneCountryData> getCountryDatasByPhone(String phone) {
  phone = toNumericString(phone);
  if (phone.isEmpty || phone.length < 11) {
    return <PhoneCountryData>[];
  }
  var phoneCode = phone.substring(0, phone.length - 10);
  return PhoneCodes.getAllCountryDatasByPhoneCode(phoneCode);
}

class PhoneCountryData {
  final String? country;

  /// this field is used to store real phone code
  /// for most countries it will be the same as internalPhoneCode
  /// but there are cases when system need another internal code
  /// to tell apart similar phone code e.g. Russia and Kazakhstan
  /// Kazakhstan has the same code as Russia +7 but internal code is 77
  /// because most phones there start with 77 while in Russia it's 79
  final String? phoneCode;
  final String? countryCode;
  final String? phoneMask;

  /// this field is used for those countries
  /// there there is more than one possible masks
  /// e.g. Brazil. In most cases this field is null
  /// IMPORTANT! all masks MUST be placed in an ascending order
  /// e.g. the shortest possible mask must be placed in a phoneMask
  /// variable, the longer ones must be in altMasks list starting from
  /// the shortest. That's because they are checked in a direct order
  /// on a user input
  final List<String>? altMasks;

  PhoneCountryData._init({
    this.country,
    this.countryCode,
    this.phoneMask,
    this.altMasks,
    this.phoneCode,
  });

  String phoneCodeToString() {
    return '+$phoneCode';
  }

  factory PhoneCountryData.fromMap(Map value) {
    final countryData = PhoneCountryData._init(
      country: value['country'],

      /// not all countryDatas need to separate phoneCode and
      /// internalPhoneCode. In most cases they are the same
      /// so we only need to check if the field is present and set
      /// the dafult one if not
      phoneCode: value['phoneCode'] ?? value['internalPhoneCode'],
      countryCode: value['countryCode'],
      phoneMask: value['phoneMask'],
      altMasks: value['altMasks'],
    );
    return countryData;
  }

  @override
  String toString() {
    return '[PhoneCountryData(country: $country,' +
        ' phoneCode: $phoneCode, countryCode: $countryCode)]';
  }
}

class PhoneCodes {
  /// рекурсивно ищет в номере телефона код страны, начиная с конца
  /// нужно для того, чтобы даже после setState и обнуления данных страны
  /// снова правильно отформатировать телефон
  static PhoneCountryData? getCountryDataByPhone(
    String phone, {
    int? subscringLength,
  }) {
    if (phone.isEmpty) return null;
    subscringLength = subscringLength ?? phone.length;

    if (subscringLength < 1) return null;
    var phoneCode = phone.substring(0, subscringLength);

    var rawData = _data.firstWhereOrNull(
      (data) => toNumericString(data!['internalPhoneCode']) == phoneCode,
    );
    if (rawData != null) {
      return PhoneCountryData.fromMap(rawData);
    }
    return getCountryDataByPhone(phone, subscringLength: subscringLength - 1);
  }

  static List<PhoneCountryData> getAllCountryDatasByPhoneCode(
    String phoneCode,
  ) {
    var list = <PhoneCountryData>[];
    _data.forEach((data) {
      var c = toNumericString(data!['internalPhoneCode']);
      if (c == phoneCode) {
        list.add(PhoneCountryData.fromMap(data));
      }
    });
    return list;
  }

  static List<Map<String, dynamic>?> _data = <Map<String, dynamic>?>[
    {
      'country': 'Afghanistan',
      'internalPhoneCode': '93',
      'countryCode': 'AF',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Albania',
      'internalPhoneCode': '355',
      'countryCode': 'AL',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Algeria',
      'internalPhoneCode': '213',
      'countryCode': 'DZ',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'American Samoa',
      'internalPhoneCode': '1684',
      'countryCode': 'AS',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Andorra',
      'internalPhoneCode': '376',
      'countryCode': 'AD',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Angola',
      'internalPhoneCode': '244',
      'countryCode': 'AO',
      'phoneMask': '+000 0000 000 0000',
    },
    {
      'country': 'Anguilla',
      'internalPhoneCode': '1264',
      'countryCode': 'AI',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Antigua and Barbuda',
      'internalPhoneCode': '1268',
      'countryCode': 'AG',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Argentina',
      'internalPhoneCode': '54',
      'countryCode': 'AR',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': 'Armenia',
      'internalPhoneCode': '374',
      'countryCode': 'AM',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Aruba',
      'internalPhoneCode': '297',
      'countryCode': 'AW',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Australia',
      'internalPhoneCode': '61',
      'countryCode': 'AU',
      'phoneMask': '+00 0000 0000',
      'altMasks': [
        '+00 0 0000 0000',
      ],
    },
    {
      'country': 'Austria',
      'internalPhoneCode': '43',
      'countryCode': 'AT',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Azerbaijan',
      'internalPhoneCode': '994',
      'countryCode': 'AZ',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Bahamas',
      'internalPhoneCode': '1242',
      'countryCode': 'BS',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Bahrain',
      'internalPhoneCode': '973',
      'countryCode': 'BH',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Bangladesh',
      'internalPhoneCode': '880',
      'countryCode': 'BD',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Barbados',
      'internalPhoneCode': '1246',
      'countryCode': 'BB',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Belarus',
      'internalPhoneCode': '375',
      'countryCode': 'BY',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Belgium',
      'internalPhoneCode': '32',
      'countryCode': 'BE',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Belize',
      'internalPhoneCode': '501',
      'countryCode': 'BZ',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Benin',
      'internalPhoneCode': '229',
      'countryCode': 'BJ',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Bermuda',
      'internalPhoneCode': '1441',
      'countryCode': 'BM',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Bhutan',
      'internalPhoneCode': '975',
      'countryCode': 'BT',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Bosnia and Herzegovina',
      'internalPhoneCode': '387',
      'countryCode': 'BA',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Botswana',
      'internalPhoneCode': '267',
      'countryCode': 'BW',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Brazil',
      'internalPhoneCode': '55',
      'countryCode': 'BR',
      'phoneMask': '+00 (00) 0000-0000',
      'altMasks': [
        '+00 (00) 00000-0000',
      ],
    },
    {
      'country': 'British Indian Ocean Territory',
      'internalPhoneCode': '246',
      'countryCode': 'IO',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Bulgaria',
      'internalPhoneCode': '359',
      'countryCode': 'BG',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Burkina Faso',
      'internalPhoneCode': '226',
      'countryCode': 'BF',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Burundi',
      'internalPhoneCode': '257',
      'countryCode': 'BI',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Cambodia',
      'internalPhoneCode': '855',
      'countryCode': 'KH',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Cameroon',
      'internalPhoneCode': '237',
      'countryCode': 'CM',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'United States',
      'internalPhoneCode': '1',
      'countryCode': 'US',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Canada',
      'internalPhoneCode': '1',
      'countryCode': 'CA',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Cape Verde',
      'internalPhoneCode': '238',
      'countryCode': 'CV',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Cayman Islands',
      'internalPhoneCode': ' 345',
      'countryCode': 'KY',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Central African Republic',
      'internalPhoneCode': '236',
      'countryCode': 'CF',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Chad',
      'internalPhoneCode': '235',
      'countryCode': 'TD',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Chile',
      'internalPhoneCode': '56',
      'countryCode': 'CL',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'China',
      'internalPhoneCode': '86',
      'countryCode': 'CN',
      'phoneMask': '+00 000 0000 0000',
    },
    {
      'country': 'Christmas Island',
      'internalPhoneCode': '61',
      'countryCode': 'CX',
      'phoneMask': '+00 0 0000 0000',
    },
    {
      'country': 'Colombia',
      'internalPhoneCode': '57',
      'countryCode': 'CO',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Comoros',
      'internalPhoneCode': '269',
      'countryCode': 'KM',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Congo',
      'internalPhoneCode': '242',
      'countryCode': 'CG',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Cook Islands',
      'internalPhoneCode': '682',
      'countryCode': 'CK',
      'phoneMask': '+682 00 000',
    },
    {
      'country': 'Costa Rica',
      'internalPhoneCode': '506',
      'countryCode': 'CR',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Croatia',
      'internalPhoneCode': '385',
      'countryCode': 'HR',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Cuba',
      'internalPhoneCode': '53',
      'countryCode': 'CU',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Cyprus',
      'internalPhoneCode': '357',
      'countryCode': 'CY',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Czech Republic',
      'internalPhoneCode': '420',
      'countryCode': 'CZ',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Denmark',
      'internalPhoneCode': '45',
      'countryCode': 'DK',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': 'Djibouti',
      'internalPhoneCode': '253',
      'countryCode': 'DJ',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Dominica',
      'internalPhoneCode': '1767',
      'countryCode': 'DM',
      'phoneMask': '+0000 000 0000',
    },
    {
      'country': 'Dominican Republic',
      'internalPhoneCode': '1809',
      'countryCode': 'DO',
      'phoneMask': '+0000 000 0000',
    },
    {
      'country': 'Ecuador',
      'internalPhoneCode': '593',
      'countryCode': 'EC',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Egypt',
      'internalPhoneCode': '20',
      'countryCode': 'EG',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'El Salvador',
      'internalPhoneCode': '503',
      'countryCode': 'SV',
      'phoneMask': '+000 00 0000 0000',
    },
    {
      'country': 'Equatorial Guinea',
      'internalPhoneCode': '240',
      'countryCode': 'GQ',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Eritrea',
      'internalPhoneCode': '291',
      'countryCode': 'ER',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Estonia',
      'internalPhoneCode': '372',
      'countryCode': 'EE',
      'phoneMask': '+000 000 000',
      'altMasks': [
        '+000 000 0000',
        '+000 0000 0000',
        '+000 000000000',
      ]
    },
    {
      'country': 'Ethiopia',
      'internalPhoneCode': '251',
      'countryCode': 'ET',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Faroe Islands',
      'internalPhoneCode': '298',
      'countryCode': 'FO',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'Fiji',
      'internalPhoneCode': '679',
      'countryCode': 'FJ',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Finland',
      'internalPhoneCode': '358',
      'countryCode': 'FI',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'France',
      'internalPhoneCode': '33',
      'countryCode': 'FR',
      'phoneMask': '+00 0 00 00 00 00',
    },
    {
      'country': 'French Guiana',
      'internalPhoneCode': '594',
      'countryCode': 'GF',
      'phoneMask': '+000 000 00 00 00',
    },
    {
      'country': 'French Polynesia',
      'internalPhoneCode': '689',
      'countryCode': 'PF',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'Gabon',
      'internalPhoneCode': '241',
      'countryCode': 'GA',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'Gambia',
      'internalPhoneCode': '220',
      'countryCode': 'GM',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Georgia',
      'internalPhoneCode': '995',
      'countryCode': 'GE',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Germany',
      'internalPhoneCode': '49',
      'countryCode': 'DE',
      'phoneMask': '+00 00 000000000',
    },
    {
      'country': 'Ghana',
      'internalPhoneCode': '233',
      'countryCode': 'GH',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Gibraltar',
      'internalPhoneCode': '350',
      'countryCode': 'GI',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'Greece',
      'internalPhoneCode': '30',
      'countryCode': 'GR',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': 'Greenland',
      'internalPhoneCode': '299',
      'countryCode': 'GL',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'Grenada',
      'internalPhoneCode': '1473',
      'countryCode': 'GD',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Guadeloupe',
      'internalPhoneCode': '590',
      'countryCode': 'GP',
      'phoneMask': '+000 000 00 00 00',
    },
    {
      'country': 'Guam',
      'internalPhoneCode': '1671',
      'countryCode': 'GU',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Guatemala',
      'internalPhoneCode': '502',
      'countryCode': 'GT',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Guinea',
      'internalPhoneCode': '224',
      'countryCode': 'GN',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Guinea-Bissau',
      'internalPhoneCode': '245',
      'countryCode': 'GW',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Guyana',
      'internalPhoneCode': '592',
      'countryCode': 'GY',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Haiti',
      'internalPhoneCode': '509',
      'countryCode': 'HT',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Honduras',
      'internalPhoneCode': '504',
      'countryCode': 'HN',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Hungary',
      'internalPhoneCode': '36',
      'countryCode': 'HU',
      'phoneMask': '+00 0 000 0000',
      'altMasks': [
        '+00 00 000 0000',
      ],
    },
    {
      'country': 'Hungary (Alternative)',
      'internalPhoneCode': '06',
      'countryCode': 'HU',
      'phoneMask': '+00 0 000 0000',
      'altMasks': [
        '+00 00 000 0000',
      ],
    },
    {
      'country': 'Iceland',
      'internalPhoneCode': '354',
      'countryCode': 'IS',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'India',
      'internalPhoneCode': '91',
      'countryCode': 'IN',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Indonesia',
      'internalPhoneCode': '62',
      'countryCode': 'ID',
      'phoneMask': '+00 00 0000 0000',
    },
    {
      'country': 'Iraq',
      'internalPhoneCode': '964',
      'countryCode': 'IQ',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Ireland',
      'internalPhoneCode': '353',
      'countryCode': 'IE',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Israel',
      'internalPhoneCode': '972',
      'countryCode': 'IL',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Italy',
      'internalPhoneCode': '39',
      'countryCode': 'IT',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Jamaica',
      'internalPhoneCode': '1876',
      'countryCode': 'JM',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Japan',
      'internalPhoneCode': '81',
      'countryCode': 'JP',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Jordan',
      'internalPhoneCode': '962',
      'countryCode': 'JO',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Kazakhstan',
      'internalPhoneCode': '77',
      'phoneCode': '7',
      'countryCode': 'KZ',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Kenya',
      'internalPhoneCode': '254',
      'countryCode': 'KE',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Kiribati',
      'internalPhoneCode': '686',
      'countryCode': 'KI',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'Kuwait',
      'internalPhoneCode': '965',
      'countryCode': 'KW',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Kyrgyzstan',
      'internalPhoneCode': '996',
      'countryCode': 'KG',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Latvia',
      'internalPhoneCode': '371',
      'countryCode': 'LV',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Lebanon',
      'internalPhoneCode': '961',
      'countryCode': 'LB',
      'phoneMask': '+000 00 000 000',
    },
    {
      'country': 'Lesotho',
      'internalPhoneCode': '266',
      'countryCode': 'LS',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Liberia',
      'internalPhoneCode': '231',
      'countryCode': 'LR',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Liechtenstein',
      'internalPhoneCode': '423',
      'countryCode': 'LI',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Lithuania',
      'internalPhoneCode': '370',
      'countryCode': 'LT',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Luxembourg',
      'internalPhoneCode': '352',
      'countryCode': 'LU',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'Madagascar',
      'internalPhoneCode': '261',
      'countryCode': 'MG',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Malawi',
      'internalPhoneCode': '265',
      'countryCode': 'MW',
      'phoneMask': '+000 000000000',
    },
    {
      'country': 'Malaysia',
      'internalPhoneCode': '60',
      'countryCode': 'MY',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': 'Maldives',
      'internalPhoneCode': '960',
      'countryCode': 'MV',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Mali',
      'internalPhoneCode': '223',
      'countryCode': 'ML',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Malta',
      'internalPhoneCode': '356',
      'countryCode': 'MT',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Marshall Islands',
      'internalPhoneCode': '692',
      'countryCode': 'MH',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Martinique',
      'internalPhoneCode': '596',
      'countryCode': 'MQ',
      'phoneMask': '+000 000 00 00 00',
    },
    {
      'country': 'Mauritania',
      'internalPhoneCode': '222',
      'countryCode': 'MR',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Mauritius',
      'internalPhoneCode': '230',
      'countryCode': 'MU',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Mayotte',
      'internalPhoneCode': '262',
      'countryCode': 'YT',
      'phoneMask': '+000 000 00 00 00',
    },
    {
      'country': 'Mexico',
      'internalPhoneCode': '52',
      'countryCode': 'MX',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Monaco',
      'internalPhoneCode': '377',
      'countryCode': 'MC',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Mongolia',
      'internalPhoneCode': '976',
      'countryCode': 'MN',
      'phoneMask': '+000 00 000000',
    },
    {
      'country': 'Montenegro',
      'internalPhoneCode': '382',
      'countryCode': 'ME',
      'phoneMask': '+000 00 000000',
    },
    {
      'country': 'Montserrat',
      'internalPhoneCode': '1664',
      'countryCode': 'MS',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Morocco',
      'internalPhoneCode': '212',
      'countryCode': 'MA',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Myanmar',
      'internalPhoneCode': '95',
      'countryCode': 'MM',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Namibia',
      'internalPhoneCode': '264',
      'countryCode': 'NA',
      'phoneMask': '+000 00 000000',
    },
    {
      'country': 'Nauru',
      'internalPhoneCode': '674',
      'countryCode': 'NR',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Nepal',
      'internalPhoneCode': '977',
      'countryCode': 'NP',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Netherlands',
      'internalPhoneCode': '31',
      'countryCode': 'NL',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Netherlands Antilles',
      'internalPhoneCode': '599',
      'countryCode': 'AN',
      'phoneMask': '+000 00000000',
    },
    {
      'country': 'New Caledonia',
      'internalPhoneCode': '687',
      'countryCode': 'NC',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'New Zealand',
      'internalPhoneCode': '64',
      'countryCode': 'NZ',
      'phoneMask': '+00 (0) 000 0000',
      'altMasks': [
        '+00 (00) 000 0000',
        '+00 (000) 000 0000',
      ],
    },
    {
      'country': 'Nicaragua',
      'internalPhoneCode': '505',
      'countryCode': 'NI',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Niger',
      'internalPhoneCode': '227',
      'countryCode': 'NE',
      'phoneMask': '+000 00 000000',
    },
    {
      'country': 'Nigeria',
      'internalPhoneCode': '234',
      'countryCode': 'NG',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Niue',
      'internalPhoneCode': '683',
      'countryCode': 'NU',
      'phoneMask': '+000 0000000',
    },
    {
      'country': 'Norfolk Island',
      'internalPhoneCode': '672',
      'countryCode': 'NF',
      'phoneMask': '+000 0 00 000',
    },
    {
      'country': 'Northern Mariana Islands',
      'internalPhoneCode': '1670',
      'countryCode': 'MP',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Norway',
      'internalPhoneCode': '47',
      'countryCode': 'NO',
      'phoneMask': '+00 0000 0000',
    },
    {
      'country': 'Oman',
      'internalPhoneCode': '968',
      'countryCode': 'OM',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Pakistan',
      'internalPhoneCode': '92',
      'countryCode': 'PK',
      'phoneMask': '+00 0000000',
    },
    {
      'country': 'Palau',
      'internalPhoneCode': '680',
      'countryCode': 'PW',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Panama',
      'internalPhoneCode': '507',
      'countryCode': 'PA',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Papua New Guinea',
      'internalPhoneCode': '675',
      'countryCode': 'PG',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Paraguay',
      'internalPhoneCode': '595',
      'countryCode': 'PY',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Peru',
      'internalPhoneCode': '51',
      'countryCode': 'PE',
      'phoneMask': '+00 00 000000000',
    },
    {
      'country': 'Philippines',
      'internalPhoneCode': '63',
      'countryCode': 'PH',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Poland',
      'internalPhoneCode': '48',
      'countryCode': 'PL',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Portugal',
      'internalPhoneCode': '351',
      'countryCode': 'PT',
      'phoneMask': '+000 000 000 000',
    },
    {
      'country': 'Puerto Rico',
      'internalPhoneCode': '1939',
      'countryCode': 'PR',
      'phoneMask': '+0000 000 0000',
    },
    {
      'country': 'Qatar',
      'internalPhoneCode': '974',
      'countryCode': 'QA',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Romania',
      'internalPhoneCode': '40',
      'countryCode': 'RO',
      'phoneMask': '+00 000 000 000',
    },
    {
      'country': 'Rwanda',
      'internalPhoneCode': '250',
      'countryCode': 'RW',
      'phoneMask': '000 000 000',
    },
    {
      'country': 'Samoa',
      'internalPhoneCode': '685',
      'countryCode': 'WS',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'San Marino',
      'internalPhoneCode': '378',
      'countryCode': 'SM',
      'phoneMask': '+000 0000 000000',
    },
    {
      'country': 'Saudi Arabia',
      'internalPhoneCode': '966',
      'countryCode': 'SA',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Senegal',
      'internalPhoneCode': '221',
      'countryCode': 'SN',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Serbia',
      'internalPhoneCode': '381',
      'countryCode': 'RS',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Seychelles',
      'internalPhoneCode': '248',
      'countryCode': 'SC',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Sierra Leone',
      'internalPhoneCode': '232',
      'countryCode': 'SL',
      'phoneMask': '+000 00 000000',
    },
    {
      'country': 'Singapore',
      'internalPhoneCode': '65',
      'countryCode': 'SG',
      'phoneMask': '+00 0000 0000',
    },
    {
      'country': 'Slovakia',
      'internalPhoneCode': '421',
      'countryCode': 'SK',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Slovenia',
      'internalPhoneCode': '386',
      'countryCode': 'SI',
      'phoneMask': '+000 0 000 00 00',
    },
    {
      'country': 'Solomon Islands',
      'internalPhoneCode': '677',
      'countryCode': 'SB',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'South Africa',
      'internalPhoneCode': '27',
      'countryCode': 'ZA',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'South Georgia and the South Sandwich Islands',
      'internalPhoneCode': '500',
      'countryCode': 'GS',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'Spain',
      'internalPhoneCode': '34',
      'countryCode': 'ES',
      'phoneMask': '+00 000 000 000',
    },
    {
      'country': 'Sri Lanka',
      'internalPhoneCode': '94',
      'countryCode': 'LK',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Sudan',
      'internalPhoneCode': '249',
      'countryCode': 'SD',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Suriname',
      'internalPhoneCode': '597',
      'countryCode': 'SR',
      'phoneMask': '+000 000000',
    },
    {
      'country': 'Swaziland',
      'internalPhoneCode': '268',
      'countryCode': 'SZ',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Sweden',
      'internalPhoneCode': '46',
      'countryCode': 'SE',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Switzerland',
      'internalPhoneCode': '41',
      'countryCode': 'CH',
      'phoneMask': '+00 00 000 0000',
    },
    {
      'country': 'Tajikistan',
      'internalPhoneCode': '992',
      'countryCode': 'TJ',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Thailand',
      'internalPhoneCode': '66',
      'countryCode': 'TH',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': 'Togo',
      'internalPhoneCode': '228',
      'countryCode': 'TG',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Tokelau',
      'internalPhoneCode': '690',
      'countryCode': 'TK',
      'phoneMask': '+000 0000',
    },
    {
      'country': 'Tonga',
      'internalPhoneCode': '676',
      'countryCode': 'TO',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Trinidad and Tobago',
      'internalPhoneCode': '1868',
      'countryCode': 'TT',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Tunisia',
      'internalPhoneCode': '216',
      'countryCode': 'TN',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Turkey',
      'internalPhoneCode': '90',
      'countryCode': 'TR',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Turkmenistan',
      'internalPhoneCode': '993',
      'countryCode': 'TM',
      'phoneMask': '+000 00 000000',
    },
    {
      'country': 'Turks and Caicos Islands',
      'internalPhoneCode': '1649',
      'countryCode': 'TC',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Tuvalu',
      'internalPhoneCode': '688',
      'countryCode': 'TV',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'Uganda',
      'internalPhoneCode': '256',
      'countryCode': 'UG',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Ukraine',
      'internalPhoneCode': '380',
      'countryCode': 'UA',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'United Arab Emirates',
      'internalPhoneCode': '971',
      'countryCode': 'AE',
      'phoneMask': '+000 00 000000',
      'altMasks': [
        '+000 00 0000000',
      ],
    },
    {
      'country': 'United Kingdom',
      'internalPhoneCode': '44',
      'countryCode': 'GB',
      'phoneMask': '+00 0000 000000',
    },
    {
      'country': 'Uruguay',
      'internalPhoneCode': '598',
      'countryCode': 'UY',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Uzbekistan',
      'internalPhoneCode': '998',
      'countryCode': 'UZ',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Vanuatu',
      'internalPhoneCode': '678',
      'countryCode': 'VU',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'Wallis and Futuna',
      'internalPhoneCode': '681',
      'countryCode': 'WF',
      'phoneMask': '‎+000 00 0000',
    },
    {
      'country': 'Yemen',
      'internalPhoneCode': '967',
      'countryCode': 'YE',
      'phoneMask': '+000 0 000000',
    },
    {
      'country': 'Zambia',
      'internalPhoneCode': '260',
      'countryCode': 'ZM',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Zimbabwe',
      'internalPhoneCode': '263',
      'countryCode': 'ZW',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Land Islands',
      'internalPhoneCode': '354',
      'countryCode': 'AX',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Bolivia, Plurinational State of',
      'internalPhoneCode': '591',
      'countryCode': 'BO',
      'phoneMask': '+000 000 000 0000',
    },
    {
      'country': 'Brunei Darussalam',
      'internalPhoneCode': '673',
      'countryCode': 'BN',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Cocos (Keeling) Islands',
      'internalPhoneCode': '61',
      'countryCode': 'CC',
      'phoneMask': '+00 0 0000 0000',
    },
    {
      'country': 'Congo, The Democratic Republic of the',
      'internalPhoneCode': '243',
      'countryCode': 'CD',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Cote d\'Ivoire',
      'internalPhoneCode': '225',
      'countryCode': 'CI',
      'phoneMask': '+000 00000000',
    },
    {
      'country': 'Falkland Islands (Malvinas)',
      'internalPhoneCode': '500',
      'countryCode': 'FK',
      'phoneMask': '+000 00000',
    },
    {
      'country': 'Guernsey',
      'internalPhoneCode': '44',
      'countryCode': 'GG',
      'phoneMask': '+00 (0) 0000 000000',
    },
    {
      'country': 'Hong Kong',
      'internalPhoneCode': '852',
      'countryCode': 'HK',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Iran, Islamic Republic of',
      'internalPhoneCode': '98',
      'countryCode': 'IR',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Korea, Democratic People\'s Republic of',
      'internalPhoneCode': '850',
      'countryCode': 'KP',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Korea, Republic of',
      'internalPhoneCode': '82',
      'countryCode': 'KR',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': '(Laos) Lao People\'s Democratic Republic',
      'internalPhoneCode': '856',
      'countryCode': 'LA',
      'phoneMask': '+000 00 0000 0000',
    },
    {
      'country': 'Libyan Arab Jamahiriya',
      'internalPhoneCode': '218',
      'countryCode': 'LY',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Macao',
      'internalPhoneCode': '853',
      'countryCode': 'MO',
      'phoneMask': '+000 0000 0000',
    },
    {
      'country': 'Macedonia',
      'internalPhoneCode': '389',
      'countryCode': 'MK',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Micronesia, Federated States of',
      'internalPhoneCode': '691',
      'countryCode': 'FM',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Moldova, Republic of',
      'internalPhoneCode': '373',
      'countryCode': 'MD',
      'phoneMask': '+000 000 00000',
    },
    {
      'country': 'Mozambique',
      'internalPhoneCode': '258',
      'countryCode': 'MZ',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Palestina',
      'internalPhoneCode': '970',
      'countryCode': 'PS',
      'phoneMask': '+000 0 000 0000',
    },
    {
      'country': 'Pitcairn',
      'internalPhoneCode': '64',
      'countryCode': 'PN',
      'phoneMask': '+00 0 000 0000',
    },
    {
      'country': 'Réunion',
      'internalPhoneCode': '262',
      'countryCode': 'RE',
      'phoneMask': '+000 000 00 00 00',
    },
    {
      'country': 'Russia',
      'internalPhoneCode': '7',
      'countryCode': 'RU',
      'phoneMask': '+0 (000) 000-00-00',
    },
    {
      'country': 'Saint Barthélemy',
      'internalPhoneCode': '590',
      'countryCode': 'BL',
      'phoneMask': '+000 000 00 00 00',
    },
    {
      'country': 'Saint Helena, Ascension and Tristan Da Cunha',
      'internalPhoneCode': '290',
      'countryCode': 'SH',
      'phoneMask': '+000 0000',
    },
    {
      'country': 'Saint Kitts and Nevis',
      'internalPhoneCode': '1869',
      'countryCode': 'KN',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Saint Lucia',
      'internalPhoneCode': '1758',
      'countryCode': 'LC',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Saint Martin',
      'internalPhoneCode': '590',
      'countryCode': 'MF',
      'phoneMask': '+000 000 000000',
    },
    {
      'country': 'Saint Pierre and Miquelon',
      'internalPhoneCode': '508',
      'countryCode': 'PM',
      'phoneMask': '+508 00 00 00',
    },
    {
      'country': 'Saint Vincent and the Grenadines',
      'internalPhoneCode': '1784',
      'countryCode': 'VC',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Sao Tome and Principe',
      'internalPhoneCode': '239',
      'countryCode': 'ST',
      'phoneMask': '+000 000 0000',
    },
    {
      'country': 'Somalia',
      'internalPhoneCode': '252',
      'countryCode': 'SO',
      'phoneMask': '+000 00 000 000',
    },
    {
      'country': 'Svalbard and Jan Mayen',
      'internalPhoneCode': '47',
      'countryCode': 'SJ',
      'phoneMask': '+00 0000 0000',
    },
    {
      'country': 'Syrian Arab Republic',
      'internalPhoneCode': '963',
      'countryCode': 'SY',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Taiwan',
      'internalPhoneCode': '886',
      'countryCode': 'TW',
      'phoneMask': '+000 0 0000 0000',
    },
    {
      'country': 'Tanzania',
      'internalPhoneCode': '255',
      'countryCode': 'TZ',
      'phoneMask': '+000 00 000 0000',
    },
    {
      'country': 'Timor-Leste',
      'internalPhoneCode': '670',
      'countryCode': 'TL',
      'phoneMask': '+000 000 000',
    },
    {
      'country': 'Venezuela, Bolivarian Republic of',
      'internalPhoneCode': '58',
      'countryCode': 'VE',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Viet Nam',
      'internalPhoneCode': '84',
      'countryCode': 'VN',
      'phoneMask': '+00 000 000 0000',
    },
    {
      'country': 'Virgin Islands, British',
      'internalPhoneCode': '1284',
      'countryCode': 'VG',
      'phoneMask': '+0 (000) 000 0000',
    },
    {
      'country': 'Virgin Islands, U.S.',
      'internalPhoneCode': '1340',
      'countryCode': 'VI',
      'phoneMask': '+0 (000) 000 0000',
    }
  ];
}
