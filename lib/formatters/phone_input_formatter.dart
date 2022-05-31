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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_multi_formatter/formatters/code_mappings.dart';
import 'package:flutter_multi_formatter/formatters/country_data.dart';

import 'formatter_utils.dart';
import 'phone_input_enums.dart';

class PhoneInputFormatter extends TextInputFormatter {
  final ValueChanged<PhoneCountryData?>? onCountrySelected;
  final String? selectedCountryCode;
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
    this.selectedCountryCode,
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
    
    if(selectedCountryCode == null) {
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
    if (selectedCountryCode != null) {
      _countryData = PhoneCountryData.fromMap(
          _findCountryDataByCountryCode(selectedCountryCode!));
    } else {
      if (numericString.isEmpty) {
        _updateCountryData(null);
      } else {
        var countryData = PhoneCodes.getCountryDataByPhone(numericString);
        if (countryData != null) {
          _updateCountryData(countryData);
        }
      }
    }

    if (_countryData != null) {
      return _formatByMask(
        numericString,
        _countryData!.phoneMask!,
        _countryData!.altMasks,
        0,
        allowEndlessPhone,
        selectedCountryCode == null ? _countryData!.prefix! : null,
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
    // var countryData = PhoneCodes._data.firstWhereOrNull(
    //   ((m) => m!['countryCode'] == countryCode),
    // );
    var countryDataRes;

    if (countryData.containsKey(countryCode)) {
      countryDataRes = countryData[countryCode];
    }

    if (countryDataRes == null) {
      throw 'A country with a code of $countryCode is not found';
    }
    return countryDataRes;
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
  String? prefix = null,
]) {
  text = toNumericString('$text', allowHyphen: false);

  if (prefix != null) {
    mask = '$prefix $mask';
  }

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
        prefix,
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
  final String? prefix;

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
    this.prefix,
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
      prefix: value['prefix'],
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

    // var rawData = _data.firstWhereOrNull(
    //   (data) => toNumericString(data!['internalPhoneCode']) == phoneCode,
    // );
    var rawData;

    if (phoneToCountryMap.containsKey(phoneCode)) {
      String firstCountryCode = phoneToCountryMap[phoneCode]!.first;
      if (countryData.containsKey(firstCountryCode)) {
        rawData = countryData[firstCountryCode];
      }
    }

    if (rawData != null) {
      return PhoneCountryData.fromMap(rawData);
    }
    return getCountryDataByPhone(phone, subscringLength: subscringLength - 1);
  }

  static List<PhoneCountryData> getAllCountryDatasByPhoneCode(
    String phoneCode,
  ) {
    var list = <PhoneCountryData>[];

    if (phoneToCountryMap.containsKey(phoneCode)) {
      List countries = phoneToCountryMap[phoneCode]!;

      countries.forEach(
        (countryCode) {
          if (countryData.containsKey(countryCode))
            list.add(PhoneCountryData.fromMap(countryData[countryCode]!));
        },
      );
    }
    return list;
  }
}
