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

import 'phone_input_enums.dart';
import 'formatter_utils.dart';


class PhoneInputFormatter extends TextInputFormatter {

  final ValueChanged<PhoneCountryData> onCountrySelected;
  final bool useSeparators;

  PhoneCountryData _countryData;
  PhoneInputFormatter({
    this.onCountrySelected,
    this.useSeparators = true
  });

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var isErasing = newValue.text.length < oldValue.text.length;
    if (isErasing) {
      if (newValue.text.isEmpty) {
        _clearCountry();
      }
      return newValue;
    } 
    var onlyNumbers = toNumericString(newValue.text);
    if (onlyNumbers.length == 2) {
      /// хак специально для России, со вводом номера с восьмерки
      /// меняем ее на 7
      var isRussianWrongNumber = 
        onlyNumbers[0] == '8' && onlyNumbers[1] == '9' || 
        onlyNumbers[0] == '8' && onlyNumbers[1] == '3';
      if (isRussianWrongNumber) {
        onlyNumbers = '7${onlyNumbers[1]}';
        _countryData = null;
        _applyMask('7');
      }
    }
    

    String maskedValue = _applyMask(onlyNumbers);
    if (maskedValue.length == oldValue.text.length && onlyNumbers != '7') {
      return oldValue;
    }
    var endOffset = max(oldValue.text.length - oldValue.selection.end, 0);
    var selectionEnd = maskedValue.length - endOffset;
    return TextEditingValue(
      selection: TextSelection.collapsed(offset: selectionEnd),
      text: maskedValue
    );
  }
  /// this is a small dirty hask to be able to remove the firt characted
  Future _clearCountry() async {
    await Future.delayed(Duration(milliseconds: 5));
    _updateCountryData(null);
  }
  void _updateCountryData(PhoneCountryData countryData) {
    _countryData = countryData;
    if (onCountrySelected != null) {
      onCountrySelected(_countryData);
    }
  }

  String _applyMask(String numericString) {
    if (numericString.isEmpty) {
      _updateCountryData(null);
    } else {
      
      var countryData = _PhoneCodes.getCountryDataByPhone(numericString);
      if (countryData != null) {
        _updateCountryData(countryData);
      }
    }
    if (_countryData != null) {
      return _formatByMask(numericString, _countryData.phoneMask);
    } 
    return numericString;
  }
  
}


/// this method was supposed to match the whole phone number before
/// but now (as from version 1.1.7) phone masks are not restricted 
/// by length so it only checks if any part of number was matchet at all
bool isPhoneValid(String phone) {
  phone = toNumericString(phone);
  if (phone == null || phone.isEmpty) {
    return false;
  }
  var countryData = _PhoneCodes.getCountryDataByPhone(phone);
  if (countryData == null) {
    return false;
  }
  var formatted = _formatByMask(phone, countryData.phoneMask);
  var reprocessed = toNumericString(formatted);
  return reprocessed == phone;
}


String formatAsPhoneNumber(
    String phone, {
      InvalidPhoneAction invalidPhoneAction =  InvalidPhoneAction.ShowUnformatted,
      bool useSeparators = true,
  }) {
  if (!isPhoneValid(phone)) {
    switch (invalidPhoneAction) {
      case InvalidPhoneAction.ShowUnformatted:
        return phone;
        break;
      case InvalidPhoneAction.ReturnNull:
        return null;
        break;
      case InvalidPhoneAction.ShowPhoneInvalidString:
        return 'invalid phone';
        break;
    }
  }
  phone = toNumericString(phone);
  var countryData = _PhoneCodes.getCountryDataByPhone(phone);
  return _formatByMask(phone, countryData.phoneMask);

}

String _formatByMask(String text, String mask) {
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
    }
    else {
      result.add(mask[i]);
    }
  }
  
  var actualDigitsInMask = toNumericString(mask).replaceAll(',', '');
  if (actualDigitsInMask.length < text.length) {
    /// тупо разрешает ввод любого количества цифр после маски
    /// потому что хз какие там телефоны в разных прибалтиках или еще где-то
    result.add(' ');
    for (var i = actualDigitsInMask.length; i < text.length; i++) {
      result.add(text[i]);
    }
  }

  return result.join();
}

/// returns a list of country datas with a country code of 
/// the supplied phone number. The return type is List because
/// many countries and territories may share the same phone code
/// the list will contain one [PhoneCountryData] at max 
/// [returns] A list of [PhoneCountryData] datas or an empty list
List<PhoneCountryData> getCountryDatasByPhone(String phone) {
  phone = toNumericString(phone);
  if (phone == null || phone.isEmpty || phone.length < 11) {
    return <PhoneCountryData>[];
  }
  var phoneCode = phone.substring(0, phone.length - 10);
  return _PhoneCodes.getAllCountryDatasByPhoneCode(phoneCode);
} 


class PhoneCountryData {

  final String country;
  final String phoneCode;
  final String countryCode;
  final String phoneMask;

  PhoneCountryData._init({
    this.country,
    this.countryCode,
    this.phoneCode,
    this.phoneMask
  });

  String countryCodeToString() {
    return '+$phoneCode';
  }

  factory PhoneCountryData.fromMap(Map value) {
    return PhoneCountryData._init(
      country: value['country'],
      phoneCode: value['phoneCode'],
      countryCode: value['countryCode'],
      phoneMask: value['phoneMask'],
    );
  }
  @override 
  String toString() {
    return '[PhoneCountryData(country: $country,' + 
    ' phoneCode: $phoneCode, countryCode: $countryCode)]';
  }
}

class _PhoneCodes {

  /// рекурсивно ищет в номере телефона код страны, начиная с конца
  /// нужно для того, чтобы даже после setState и обнуления данных страны
  /// снова правильно отформатировать телефон
  static PhoneCountryData getCountryDataByPhone(String phone, {int subscringLength}) {
    if (phone.isEmpty) return null;
    subscringLength = subscringLength ?? phone.length;
    
    if (subscringLength < 1) return null;
    var phoneCode = phone.substring(0, subscringLength);

    var rawData = _data.firstWhere(
      (data) => toNumericString(data['phoneCode']) == phoneCode, 
      orElse: () => null
    );
    if (rawData != null) {
      return PhoneCountryData.fromMap(rawData);
    }
    return getCountryDataByPhone(phone, subscringLength: subscringLength -1);
  }
  static List<PhoneCountryData> getAllCountryDatasByPhoneCode(String phoneCode) {
    var list = <PhoneCountryData>[];
    _data.forEach((data) {
      var c = toNumericString(data['phoneCode']);
      if (c == phoneCode) {
        list.add(PhoneCountryData.fromMap(data));
      }
    });
    return list;
  }

  static List<Map<String, String>> _data = <Map<String, String>>[
   {
      'country': 'Afghanistan',
      'phoneCode': '93',
      'countryCode': 'AF',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Albania',
      'phoneCode': '355',
      'countryCode': 'AL',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Algeria',
      'phoneCode': '213',
      'countryCode': 'DZ',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'American Samoa',
      'phoneCode': '1684',
      'countryCode': 'AS',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Andorra',
      'phoneCode': '376',
      'countryCode': 'AD',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Angola',
      'phoneCode': '244',
      'countryCode': 'AO',
      'phoneMask': '+000 0000 000 0000',
   },
   {
      'country': 'Anguilla',
      'phoneCode': '1264',
      'countryCode': 'AI',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Antigua and Barbuda',
      'phoneCode': '1268',
      'countryCode': 'AG',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Argentina',
      'phoneCode': '54',
      'countryCode': 'AR',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Armenia',
      'phoneCode': '374',
      'countryCode': 'AM',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Aruba',
      'phoneCode': '297',
      'countryCode': 'AW',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Australia',
      'phoneCode': '61',
      'countryCode': 'AU',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Austria',
      'phoneCode': '43',
      'countryCode': 'AT',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Azerbaijan',
      'phoneCode': '994',
      'countryCode': 'AZ',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Bahamas',
      'phoneCode': '1242',
      'countryCode': 'BS',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Bahrain',
      'phoneCode': '973',
      'countryCode': 'BH',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Bangladesh',
      'phoneCode': '880',
      'countryCode': 'BD',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Barbados',
      'phoneCode': '1246',
      'countryCode': 'BB',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Belarus',
      'phoneCode': '375',
      'countryCode': 'BY',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Belgium',
      'phoneCode': '32',
      'countryCode': 'BE',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Belize',
      'phoneCode': '501',
      'countryCode': 'BZ',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Benin',
      'phoneCode': '229',
      'countryCode': 'BJ',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Bermuda',
      'phoneCode': '1441',
      'countryCode': 'BM',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Bhutan',
      'phoneCode': '975',
      'countryCode': 'BT',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Bosnia and Herzegovina',
      'phoneCode': '387',
      'countryCode': 'BA',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Botswana',
      'phoneCode': '267',
      'countryCode': 'BW',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Brazil',
      'phoneCode': '55',
      'countryCode': 'BR',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'British Indian Ocean Territory',
      'phoneCode': '246',
      'countryCode': 'IO',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Bulgaria',
      'phoneCode': '359',
      'countryCode': 'BG',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Burkina Faso',
      'phoneCode': '226',
      'countryCode': 'BF',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Burundi',
      'phoneCode': '257',
      'countryCode': 'BI',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Cambodia',
      'phoneCode': '855',
      'countryCode': 'KH',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Cameroon',
      'phoneCode': '237',
      'countryCode': 'CM',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'United States',
      'phoneCode': '1',
      'countryCode': 'US',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Canada',
      'phoneCode': '1',
      'countryCode': 'CA',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Cape Verde',
      'phoneCode': '238',
      'countryCode': 'CV',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Cayman Islands',
      'phoneCode': ' 345',
      'countryCode': 'KY',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Central African Republic',
      'phoneCode': '236',
      'countryCode': 'CF',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Chad',
      'phoneCode': '235',
      'countryCode': 'TD',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Chile',
      'phoneCode': '56',
      'countryCode': 'CL',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'China',
      'phoneCode': '86',
      'countryCode': 'CN',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Christmas Island',
      'phoneCode': '61',
      'countryCode': 'CX',
      'phoneMask': '+00 0 0000 0000',
   },
   {
      'country': 'Colombia',
      'phoneCode': '57',
      'countryCode': 'CO',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Comoros',
      'phoneCode': '269',
      'countryCode': 'KM',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Congo',
      'phoneCode': '242',
      'countryCode': 'CG',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Cook Islands',
      'phoneCode': '682',
      'countryCode': 'CK',
      'phoneMask': '+682 00 000',
   },
   {
      'country': 'Costa Rica',
      'phoneCode': '506',
      'countryCode': 'CR',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Croatia',
      'phoneCode': '385',
      'countryCode': 'HR',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Cuba',
      'phoneCode': '53',
      'countryCode': 'CU',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Cyprus',
      'phoneCode': '537',
      'countryCode': 'CY',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Czech Republic',
      'phoneCode': '420',
      'countryCode': 'CZ',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Denmark',
      'phoneCode': '45',
      'countryCode': 'DK',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Djibouti',
      'phoneCode': '253',
      'countryCode': 'DJ',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Dominica',
      'phoneCode': '1767',
      'countryCode': 'DM',
      'phoneMask': '+0000 000 0000',
   },
   {
      'country': 'Dominican Republic',
      'phoneCode': '1809',
      'countryCode': 'DO',
      'phoneMask': '+0000 000 0000',
   },
   {
      'country': 'Ecuador',
      'phoneCode': '593',
      'countryCode': 'EC',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Egypt',
      'phoneCode': '20',
      'countryCode': 'EG',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'El Salvador',
      'phoneCode': '503',
      'countryCode': 'SV',
      'phoneMask': '+000 00 0000 0000',
   },
   {
      'country': 'Equatorial Guinea',
      'phoneCode': '240',
      'countryCode': 'GQ',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Eritrea',
      'phoneCode': '291',
      'countryCode': 'ER',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Estonia',
      'phoneCode': '372',
      'countryCode': 'EE',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Ethiopia',
      'phoneCode': '251',
      'countryCode': 'ET',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Faroe Islands',
      'phoneCode': '298',
      'countryCode': 'FO',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'Fiji',
      'phoneCode': '679',
      'countryCode': 'FJ',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Finland',
      'phoneCode': '358',
      'countryCode': 'FI',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'France',
      'phoneCode': '33',
      'countryCode': 'FR',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'French Guiana',
      'phoneCode': '594',
      'countryCode': 'GF',
      'phoneMask': '+000 00 0000 0000',
   },
   {
      'country': 'French Polynesia',
      'phoneCode': '689',
      'countryCode': 'PF',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'Gabon',
      'phoneCode': '241',
      'countryCode': 'GA',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'Gambia',
      'phoneCode': '220',
      'countryCode': 'GM',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Georgia',
      'phoneCode': '995',
      'countryCode': 'GE',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Germany',
      'phoneCode': '49',
      'countryCode': 'DE',
      'phoneMask': '+00 00 000000000',
   },
   {
      'country': 'Ghana',
      'phoneCode': '233',
      'countryCode': 'GH',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Gibraltar',
      'phoneCode': '350',
      'countryCode': 'GI',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'Greece',
      'phoneCode': '30',
      'countryCode': 'GR',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Greenland',
      'phoneCode': '299',
      'countryCode': 'GL',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'Grenada',
      'phoneCode': '1473',
      'countryCode': 'GD',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Guadeloupe',
      'phoneCode': '590',
      'countryCode': 'GP',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Guam',
      'phoneCode': '1671',
      'countryCode': 'GU',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Guatemala',
      'phoneCode': '502',
      'countryCode': 'GT',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Guinea',
      'phoneCode': '224',
      'countryCode': 'GN',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Guinea-Bissau',
      'phoneCode': '245',
      'countryCode': 'GW',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Guyana',
      'phoneCode': '595',
      'countryCode': 'GY',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Haiti',
      'phoneCode': '509',
      'countryCode': 'HT',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Honduras',
      'phoneCode': '504',
      'countryCode': 'HN',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Hungary',
      'phoneCode': '36',
      'countryCode': 'HU',
      'phoneMask': '+00 00 000 000',
   },
   {
      'country': 'Iceland',
      'phoneCode': '354',
      'countryCode': 'IS',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'India',
      'phoneCode': '91',
      'countryCode': 'IN',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Indonesia',
      'phoneCode': '62',
      'countryCode': 'ID',
      'phoneMask': '+00 00 0000 0000',
   },
   {
      'country': 'Iraq',
      'phoneCode': '964',
      'countryCode': 'IQ',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Ireland',
      'phoneCode': '353',
      'countryCode': 'IE',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Israel',
      'phoneCode': '972',
      'countryCode': 'IL',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Italy',
      'phoneCode': '39',
      'countryCode': 'IT',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Jamaica',
      'phoneCode': '1876',
      'countryCode': 'JM',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Japan',
      'phoneCode': '81',
      'countryCode': 'JP',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Jordan',
      'phoneCode': '962',
      'countryCode': 'JO',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Kazakhstan',
      'phoneCode': '77',
      'countryCode': 'KZ',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Kenya',
      'phoneCode': '254',
      'countryCode': 'KE',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Kiribati',
      'phoneCode': '686',
      'countryCode': 'KI',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'Kuwait',
      'phoneCode': '965',
      'countryCode': 'KW',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Kyrgyzstan',
      'phoneCode': '996',
      'countryCode': 'KG',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Latvia',
      'phoneCode': '371',
      'countryCode': 'LV',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Lebanon',
      'phoneCode': '961',
      'countryCode': 'LB',
      'phoneMask': '+000 00 000 000',
   },
   {
      'country': 'Lesotho',
      'phoneCode': '266',
      'countryCode': 'LS',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Liberia',
      'phoneCode': '231',
      'countryCode': 'LR',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Liechtenstein',
      'phoneCode': '423',
      'countryCode': 'LI',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Lithuania',
      'phoneCode': '370',
      'countryCode': 'LT',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Luxembourg',
      'phoneCode': '352',
      'countryCode': 'LU',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'Madagascar',
      'phoneCode': '261',
      'countryCode': 'MG',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Malawi',
      'phoneCode': '265',
      'countryCode': 'MW',
      'phoneMask': '+000 000000000',
   },
   {
      'country': 'Malaysia',
      'phoneCode': '60',
      'countryCode': 'MY',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Maldives',
      'phoneCode': '960',
      'countryCode': 'MV',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Mali',
      'phoneCode': '223',
      'countryCode': 'ML',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Malta',
      'phoneCode': '356',
      'countryCode': 'MT',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Marshall Islands',
      'phoneCode': '692',
      'countryCode': 'MH',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Martinique',
      'phoneCode': '596',
      'countryCode': 'MQ',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Mauritania',
      'phoneCode': '222',
      'countryCode': 'MR',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Mauritius',
      'phoneCode': '230',
      'countryCode': 'MU',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Mayotte',
      'phoneCode': '262',
      'countryCode': 'YT',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Mexico',
      'phoneCode': '52',
      'countryCode': 'MX',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Monaco',
      'phoneCode': '377',
      'countryCode': 'MC',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Mongolia',
      'phoneCode': '976',
      'countryCode': 'MN',
      'phoneMask': '+000 00 000000',
   },
   {
      'country': 'Montenegro',
      'phoneCode': '382',
      'countryCode': 'ME',
      'phoneMask': '+000 00 000000',
   },
   {
      'country': 'Montserrat',
      'phoneCode': '1664',
      'countryCode': 'MS',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Morocco',
      'phoneCode': '212',
      'countryCode': 'MA',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Myanmar',
      'phoneCode': '95',
      'countryCode': 'MM',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Namibia',
      'phoneCode': '264',
      'countryCode': 'NA',
      'phoneMask': '+000 00 000000',
   },
   {
      'country': 'Nauru',
      'phoneCode': '674',
      'countryCode': 'NR',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Nepal',
      'phoneCode': '977',
      'countryCode': 'NP',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Netherlands',
      'phoneCode': '31',
      'countryCode': 'NL',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Netherlands Antilles',
      'phoneCode': '599',
      'countryCode': 'AN',
      'phoneMask': '+000 00000000',
   },
   {
      'country': 'New Caledonia',
      'phoneCode': '687',
      'countryCode': 'NC',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'New Zealand',
      'phoneCode': '64',
      'countryCode': 'NZ',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Nicaragua',
      'phoneCode': '505',
      'countryCode': 'NI',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Niger',
      'phoneCode': '227',
      'countryCode': 'NE',
      'phoneMask': '+000 00 000000',
   },
   {
      'country': 'Nigeria',
      'phoneCode': '234',
      'countryCode': 'NG',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Niue',
      'phoneCode': '683',
      'countryCode': 'NU',
      'phoneMask': '+000 0000000',
   },
   {
      'country': 'Norfolk Island',
      'phoneCode': '672',
      'countryCode': 'NF',
      'phoneMask': '+000 0 00 000',
   },
   {
      'country': 'Northern Mariana Islands',
      'phoneCode': '1670',
      'countryCode': 'MP',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Norway',
      'phoneCode': '47',
      'countryCode': 'NO',
      'phoneMask': '+00 0000 0000',
   },
   {
      'country': 'Oman',
      'phoneCode': '968',
      'countryCode': 'OM',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Pakistan',
      'phoneCode': '92',
      'countryCode': 'PK',
      'phoneMask': '+00 0000000',
   },
   {
      'country': 'Palau',
      'phoneCode': '680',
      'countryCode': 'PW',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Panama',
      'phoneCode': '507',
      'countryCode': 'PA',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Papua New Guinea',
      'phoneCode': '675',
      'countryCode': 'PG',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Paraguay',
      'phoneCode': '595',
      'countryCode': 'PY',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Peru',
      'phoneCode': '51',
      'countryCode': 'PE',
      'phoneMask': '+00 00 000000000',
   },
   {
      'country': 'Philippines',
      'phoneCode': '63',
      'countryCode': 'PH',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Poland',
      'phoneCode': '48',
      'countryCode': 'PL',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Portugal',
      'phoneCode': '351',
      'countryCode': 'PT',
      'phoneMask': '+000 000 000 000',
   },
   {
      'country': 'Puerto Rico',
      'phoneCode': '1939',
      'countryCode': 'PR',
      'phoneMask': '+0000 000 0000',
   },
   {
      'country': 'Qatar',
      'phoneCode': '974',
      'countryCode': 'QA',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Romania',
      'phoneCode': '40',
      'countryCode': 'RO',
      'phoneMask': '+00 000 000 000',
   },
   {
      'country': 'Rwanda',
      'phoneCode': '250',
      'countryCode': 'RW',
      'phoneMask': '000 000 000',
   },
   {
      'country': 'Samoa',
      'phoneCode': '685',
      'countryCode': 'WS',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'San Marino',
      'phoneCode': '378',
      'countryCode': 'SM',
      'phoneMask': '+000 0000 000000',
   },
   {
      'country': 'Saudi Arabia',
      'phoneCode': '966',
      'countryCode': 'SA',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Senegal',
      'phoneCode': '221',
      'countryCode': 'SN',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Serbia',
      'phoneCode': '381',
      'countryCode': 'RS',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Seychelles',
      'phoneCode': '248',
      'countryCode': 'SC',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Sierra Leone',
      'phoneCode': '232',
      'countryCode': 'SL',
      'phoneMask': '+000 00 000000',
   },
   {
      'country': 'Singapore',
      'phoneCode': '65',
      'countryCode': 'SG',
      'phoneMask': '+00 0000 0000',
   },
   {
      'country': 'Slovakia',
      'phoneCode': '421',
      'countryCode': 'SK',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Slovenia',
      'phoneCode': '386',
      'countryCode': 'SI',
      'phoneMask': '+000 0 000 00 00',
   },
   {
      'country': 'Solomon Islands',
      'phoneCode': '677',
      'countryCode': 'SB',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'South Africa',
      'phoneCode': '27',
      'countryCode': 'ZA',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'South Georgia and the South Sandwich Islands',
      'phoneCode': '500',
      'countryCode': 'GS',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'Spain',
      'phoneCode': '34',
      'countryCode': 'ES',
      'phoneMask': '+00 000 000 000',
   },
   {
      'country': 'Sri Lanka',
      'phoneCode': '94',
      'countryCode': 'LK',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Sudan',
      'phoneCode': '249',
      'countryCode': 'SD',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Suriname',
      'phoneCode': '597',
      'countryCode': 'SR',
      'phoneMask': '+000 000000',
   },
   {
      'country': 'Swaziland',
      'phoneCode': '268',
      'countryCode': 'SZ',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Sweden',
      'phoneCode': '46',
      'countryCode': 'SE',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Switzerland',
      'phoneCode': '41',
      'countryCode': 'CH',
      'phoneMask': '+00 00 000 0000',
   },
   {
      'country': 'Tajikistan',
      'phoneCode': '992',
      'countryCode': 'TJ',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Thailand',
      'phoneCode': '66',
      'countryCode': 'TH',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Togo',
      'phoneCode': '228',
      'countryCode': 'TG',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Tokelau',
      'phoneCode': '690',
      'countryCode': 'TK',
      'phoneMask': '+000 0000',
   },
   {
      'country': 'Tonga',
      'phoneCode': '676',
      'countryCode': 'TO',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Trinidad and Tobago',
      'phoneCode': '1868',
      'countryCode': 'TT',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Tunisia',
      'phoneCode': '216',
      'countryCode': 'TN',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Turkey',
      'phoneCode': '90',
      'countryCode': 'TR',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Turkmenistan',
      'phoneCode': '993',
      'countryCode': 'TM',
      'phoneMask': '+000 00 000000',
   },
   {
      'country': 'Turks and Caicos Islands',
      'phoneCode': '1649',
      'countryCode': 'TC',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Tuvalu',
      'phoneCode': '688',
      'countryCode': 'TV',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'Uganda',
      'phoneCode': '256',
      'countryCode': 'UG',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Ukraine',
      'phoneCode': '380',
      'countryCode': 'UA',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'United Arab Emirates',
      'phoneCode': '971',
      'countryCode': 'AE',
      'phoneMask': '+000 0 0000000',
   },
   {
      'country': 'United Kingdom',
      'phoneCode': '44',
      'countryCode': 'GB',
      'phoneMask': '+00 0000 000000',
   },
   {
      'country': 'Uruguay',
      'phoneCode': '598',
      'countryCode': 'UY',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Uzbekistan',
      'phoneCode': '998',
      'countryCode': 'UZ',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Vanuatu',
      'phoneCode': '678',
      'countryCode': 'VU',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'Wallis and Futuna',
      'phoneCode': '681',
      'countryCode': 'WF',
      'phoneMask': '‎+000 00 0000',
   },
   {
      'country': 'Yemen',
      'phoneCode': '967',
      'countryCode': 'YE',
      'phoneMask': '+000 0 000000',
   },
   {
      'country': 'Zambia',
      'phoneCode': '260',
      'countryCode': 'ZM',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Zimbabwe',
      'phoneCode': '263',
      'countryCode': 'ZW',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Land Islands',
      'phoneCode': '354',
      'countryCode': 'AX',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Bolivia, Plurinational State of',
      'phoneCode': '591',
      'countryCode': 'BO',
      'phoneMask': '+000 000 000 0000',
   },
   {
      'country': 'Brunei Darussalam',
      'phoneCode': '673',
      'countryCode': 'BN',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Cocos (Keeling) Islands',
      'phoneCode': '61',
      'countryCode': 'CC',
      'phoneMask': '+00 0 0000 0000',
   },
   {
      'country': 'Congo, The Democratic Republic of the',
      'phoneCode': '243',
      'countryCode': 'CD',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Cote d\'Ivoire',
      'phoneCode': '225',
      'countryCode': 'CI',
      'phoneMask': '+000 00000000',
   },
   {
      'country': 'Falkland Islands (Malvinas)',
      'phoneCode': '500',
      'countryCode': 'FK',
      'phoneMask': '+000 00000',
   },
   {
      'country': 'Guernsey',
      'phoneCode': '44',
      'countryCode': 'GG',
      'phoneMask': '+00 (0) 0000 000000',
   },
   {
      'country': 'Hong Kong',
      'phoneCode': '852',
      'countryCode': 'HK',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Iran, Islamic Republic of',
      'phoneCode': '98',
      'countryCode': 'IR',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Korea, Democratic People\'s Republic of',
      'phoneCode': '850',
      'countryCode': 'KP',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Korea, Republic of',
      'phoneCode': '82',
      'countryCode': 'KR',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': '(Laos) Lao People\'s Democratic Republic',
      'phoneCode': '856',
      'countryCode': 'LA',
      'phoneMask': '+000 00 0000 0000',
   },
   {
      'country': 'Libyan Arab Jamahiriya',
      'phoneCode': '218',
      'countryCode': 'LY',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Macao',
      'phoneCode': '853',
      'countryCode': 'MO',
      'phoneMask': '+000 0000 0000',
   },
   {
      'country': 'Macedonia',
      'phoneCode': '389',
      'countryCode': 'MK',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Micronesia, Federated States of',
      'phoneCode': '691',
      'countryCode': 'FM',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Moldova, Republic of',
      'phoneCode': '373',
      'countryCode': 'MD',
      'phoneMask': '+000 000 00000',
   },
   {
      'country': 'Mozambique',
      'phoneCode': '258',
      'countryCode': 'MZ',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Palestina',
      'phoneCode': '970',
      'countryCode': 'PS',
      'phoneMask': '+000 0 000 0000',
   },
   {
      'country': 'Pitcairn',
      'phoneCode': '64',
      'countryCode': 'PN',
      'phoneMask': '+00 0 000 0000',
   },
   {
      'country': 'Réunion',
      'phoneCode': '262',
      'countryCode': 'RE',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Russia',
      'phoneCode': '7',
      'countryCode': 'RU',
      'phoneMask': '+0 (000) 000 00 00',
   },
   {
      'country': 'Saint Barthélemy',
      'phoneCode': '590',
      'countryCode': 'BL',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Saint Helena, Ascension and Tristan Da Cunha',
      'phoneCode': '290',
      'countryCode': 'SH',
      'phoneMask': '+000 0000',
   },
   {
      'country': 'Saint Kitts and Nevis',
      'phoneCode': '1869',
      'countryCode': 'KN',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Saint Lucia',
      'phoneCode': '1758',
      'countryCode': 'LC',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Saint Martin',
      'phoneCode': '590',
      'countryCode': 'MF',
      'phoneMask': '+000 000 000000',
   },
   {
      'country': 'Saint Pierre and Miquelon',
      'phoneCode': '508',
      'countryCode': 'PM',
      'phoneMask': '(508) 00 00 00',
   },
   {
      'country': 'Saint Vincent and the Grenadines',
      'phoneCode': '1784',
      'countryCode': 'VC',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Sao Tome and Principe',
      'phoneCode': '239',
      'countryCode': 'ST',
      'phoneMask': '+000 000 0000',
   },
   {
      'country': 'Somalia',
      'phoneCode': '252',
      'countryCode': 'SO',
      'phoneMask': '+000 00 000 000',
   },
   {
      'country': 'Svalbard and Jan Mayen',
      'phoneCode': '47',
      'countryCode': 'SJ',
      'phoneMask': '+00 0000 0000',
   },
   {
      'country': 'Syrian Arab Republic',
      'phoneCode': '963',
      'countryCode': 'SY',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Taiwan',
      'phoneCode': '886',
      'countryCode': 'TW',
      'phoneMask': '+000 0 0000 0000',
   },
   {
      'country': 'Tanzania',
      'phoneCode': '255',
      'countryCode': 'TZ',
      'phoneMask': '+000 00 000 0000',
   },
   {
      'country': 'Timor-Leste',
      'phoneCode': '670',
      'countryCode': 'TL',
      'phoneMask': '+000 000 000',
   },
   {
      'country': 'Venezuela, Bolivarian Republic of',
      'phoneCode': '58',
      'countryCode': 'VE',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Viet Nam',
      'phoneCode': '84',
      'countryCode': 'VN',
      'phoneMask': '+00 000 000 0000',
   },
   {
      'country': 'Virgin Islands, British',
      'phoneCode': '1284',
      'countryCode': 'VG',
      'phoneMask': '+0 (000) 000 0000',
   },
   {
      'country': 'Virgin Islands, U.S.',
      'phoneCode': '1340',
      'countryCode': 'VI',
      'phoneMask': '+0 (000) 000 0000',
   }
];
}