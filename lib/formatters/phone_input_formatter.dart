
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'phone_input_enums.dart';
import 'formatter_utils.dart';


class PhoneInputFormatter extends TextInputFormatter {

  final ValueChanged<PhoneCountryData> onCountrySelected;
  final AreaCodeSeparator areaCodeSeparator;
  final bool useSeparators;

  PhoneCountryData _countryData;
  PhoneInputFormatter({
    this.onCountrySelected,
    this.areaCodeSeparator = AreaCodeSeparator.Braces,
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
      /// вводится именно numericString, а не countryPhoneCode 
      /// потому что код еще не известен
      /// и он просто предполагается по всей строке
      var countryData = _PhoneCodes.getCountryDataByPhone(numericString);
      if (countryData != null) {
        _updateCountryData(countryData);
      }
    }
    if (_countryData != null) {
      var strippedNumber =  _stripCountryCode(numericString);
      var number = _countryData.countryCodeToString() + 
        _addBracesAndDashes(strippedNumber, 
          areaCodeSeparator: areaCodeSeparator,
          useSeparators: useSeparators
        );
      return number;
    } 
    return numericString;
  }
  
  String _stripCountryCode(String phoneNumber) {
    return phoneNumber.substring(_countryData.phoneCode.length, phoneNumber.length);
  }
}

/// checks not only for length and characters but also 
/// for country phone code. If it's not found the succession of numbers 
/// will not be marked as a valid phone
bool isPhoneValid(String phone) {
  phone = toNumericString(phone);
  if (phone == null || phone.isEmpty || phone.length < 11) {
    return false;
  }
  var countryPhoneCode = phone.substring(0, phone.length - 10);
  if (_PhoneCodes.getCountryDataByPhone(countryPhoneCode) == null) {
    return false;
  }
  return true;
}


String formatAsPhoneNumber(
    String phone, {
      InvalidPhoneAction invalidPhoneAction =  InvalidPhoneAction.ShowUnformatted,
      AreaCodeSeparator areaCodeSeparator = AreaCodeSeparator.Braces,
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
  var countryPhoneCode = phone.substring(0, phone.length - 10);
  var rest = _addBracesAndDashes(
    phone.substring(phone.length - 10, phone.length), 
    areaCodeSeparator: areaCodeSeparator,
    useSeparators: useSeparators
  );
  return '+$countryPhoneCode$rest';
}

/// returns a list of country datas with a country code of 
/// the supplied phone number. The return type is List but basically
/// this is necessary only for the USA and Canada. In all other cases 
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

String _addBracesAndDashes(String strippedNumber, {
    AreaCodeSeparator areaCodeSeparator = AreaCodeSeparator.Braces,
    bool useSeparators = true
}) {
  String leftSeparator;
  String rightSeparator;
  switch (areaCodeSeparator) {
    
    case AreaCodeSeparator.Braces:
      leftSeparator = ' (';
      rightSeparator = ') ';
      break;
    case AreaCodeSeparator.Dashes:
      leftSeparator = '-';
      rightSeparator = '-';
      break;
  }
  var chars = strippedNumber.split('');
  var result = <String>[];
  if (useSeparators) {
    result.add(leftSeparator);
  }
  var maxIndex = min(chars.length, 10);
  for (var i = 0; i < maxIndex; i++) {
    result.add(chars[i]);
    if (i == 2 && useSeparators) {
      result.add(rightSeparator);
    }
    else if ((i == 5 || i == 7) && useSeparators) {
      result.add('-');
    }
  }
  return result.join('');
}



class PhoneCountryData {

  final String country;
  final String phoneCode;
  final String countryCode;

  PhoneCountryData._init({
    this.country,
    this.countryCode,
    this.phoneCode
  });

  String countryCodeToString() {
    return '+$phoneCode';
  }

  factory PhoneCountryData.fromMap(Map value) {
    return PhoneCountryData._init(
      country: value['country'],
      phoneCode: value['phoneCode'],
      countryCode: value['countryCode'],
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
      'country': 'Israel',
      'phoneCode': '972',
      'countryCode': 'IL'
   },
   {
      'country': 'Afghanistan',
      'phoneCode': '93',
      'countryCode': 'AF'
   },
   {
      'country': 'Albania',
      'phoneCode': '355',
      'countryCode': 'AL'
   },
   {
      'country': 'Algeria',
      'phoneCode': '213',
      'countryCode': 'DZ'
   },
   {
      'country': 'American Samoa',
      'phoneCode': '1684',
      'countryCode': 'AS'
   },
   {
      'country': 'Andorra',
      'phoneCode': '376',
      'countryCode': 'AD'
   },
   {
      'country': 'Angola',
      'phoneCode': '244',
      'countryCode': 'AO'
   },
   {
      'country': 'Anguilla',
      'phoneCode': '1264',
      'countryCode': 'AI'
   },
   {
      'country': 'Antigua and Barbuda',
      'phoneCode': '1268',
      'countryCode': 'AG'
   },
   {
      'country': 'Argentina',
      'phoneCode': '54',
      'countryCode': 'AR'
   },
   {
      'country': 'Armenia',
      'phoneCode': '374',
      'countryCode': 'AM'
   },
   {
      'country': 'Aruba',
      'phoneCode': '297',
      'countryCode': 'AW'
   },
   {
      'country': 'Australia',
      'phoneCode': '61',
      'countryCode': 'AU'
   },
   {
      'country': 'Austria',
      'phoneCode': '43',
      'countryCode': 'AT'
   },
   {
      'country': 'Azerbaijan',
      'phoneCode': '994',
      'countryCode': 'AZ'
   },
   {
      'country': 'Bahamas',
      'phoneCode': '1242',
      'countryCode': 'BS'
   },
   {
      'country': 'Bahrain',
      'phoneCode': '973',
      'countryCode': 'BH'
   },
   {
      'country': 'Bangladesh',
      'phoneCode': '880',
      'countryCode': 'BD'
   },
   {
      'country': 'Barbados',
      'phoneCode': '1246',
      'countryCode': 'BB'
   },
   {
      'country': 'Belarus',
      'phoneCode': '375',
      'countryCode': 'BY'
   },
   {
      'country': 'Belgium',
      'phoneCode': '32',
      'countryCode': 'BE'
   },
   {
      'country': 'Belize',
      'phoneCode': '501',
      'countryCode': 'BZ'
   },
   {
      'country': 'Benin',
      'phoneCode': '229',
      'countryCode': 'BJ'
   },
   {
      'country': 'Bermuda',
      'phoneCode': '1441',
      'countryCode': 'BM'
   },
   {
      'country': 'Bhutan',
      'phoneCode': '975',
      'countryCode': 'BT'
   },
   {
      'country': 'Bosnia and Herzegovina',
      'phoneCode': '387',
      'countryCode': 'BA'
   },
   {
      'country': 'Botswana',
      'phoneCode': '267',
      'countryCode': 'BW'
   },
   {
      'country': 'Brazil',
      'phoneCode': '55',
      'countryCode': 'BR'
   },
   {
      'country': 'British Indian Ocean Territory',
      'phoneCode': '246',
      'countryCode': 'IO'
   },
   {
      'country': 'Bulgaria',
      'phoneCode': '359',
      'countryCode': 'BG'
   },
   {
      'country': 'Burkina Faso',
      'phoneCode': '226',
      'countryCode': 'BF'
   },
   {
      'country': 'Burundi',
      'phoneCode': '257',
      'countryCode': 'BI'
   },
   {
      'country': 'Cambodia',
      'phoneCode': '855',
      'countryCode': 'KH'
   },
   {
      'country': 'Cameroon',
      'phoneCode': '237',
      'countryCode': 'CM'
   },
   {
      'country': 'United States',
      'phoneCode': '1',
      'countryCode': 'US'
   },
   {
      'country': 'Canada',
      'phoneCode': '1',
      'countryCode': 'CA'
   },
   {
      'country': 'Cape Verde',
      'phoneCode': '238',
      'countryCode': 'CV'
   },
   {
      'country': 'Cayman Islands',
      'phoneCode': ' 345',
      'countryCode': 'KY'
   },
   {
      'country': 'Central African Republic',
      'phoneCode': '236',
      'countryCode': 'CF'
   },
   {
      'country': 'Chad',
      'phoneCode': '235',
      'countryCode': 'TD'
   },
   {
      'country': 'Chile',
      'phoneCode': '56',
      'countryCode': 'CL'
   },
   {
      'country': 'China',
      'phoneCode': '86',
      'countryCode': 'CN'
   },
   {
      'country': 'Christmas Island',
      'phoneCode': '61',
      'countryCode': 'CX'
   },
   {
      'country': 'Colombia',
      'phoneCode': '57',
      'countryCode': 'CO'
   },
   {
      'country': 'Comoros',
      'phoneCode': '269',
      'countryCode': 'KM'
   },
   {
      'country': 'Congo',
      'phoneCode': '242',
      'countryCode': 'CG'
   },
   {
      'country': 'Cook Islands',
      'phoneCode': '682',
      'countryCode': 'CK'
   },
   {
      'country': 'Costa Rica',
      'phoneCode': '506',
      'countryCode': 'CR'
   },
   {
      'country': 'Croatia',
      'phoneCode': '385',
      'countryCode': 'HR'
   },
   {
      'country': 'Cuba',
      'phoneCode': '53',
      'countryCode': 'CU'
   },
   {
      'country': 'Cyprus',
      'phoneCode': '537',
      'countryCode': 'CY'
   },
   {
      'country': 'Czech Republic',
      'phoneCode': '420',
      'countryCode': 'CZ'
   },
   {
      'country': 'Denmark',
      'phoneCode': '45',
      'countryCode': 'DK'
   },
   {
      'country': 'Djibouti',
      'phoneCode': '253',
      'countryCode': 'DJ'
   },
   {
      'country': 'Dominica',
      'phoneCode': '1767',
      'countryCode': 'DM'
   },
   {
      'country': 'Dominican Republic',
      'phoneCode': '1849',
      'countryCode': 'DO'
   },
   {
      'country': 'Ecuador',
      'phoneCode': '593',
      'countryCode': 'EC'
   },
   {
      'country': 'Egypt',
      'phoneCode': '20',
      'countryCode': 'EG'
   },
   {
      'country': 'El Salvador',
      'phoneCode': '503',
      'countryCode': 'SV'
   },
   {
      'country': 'Equatorial Guinea',
      'phoneCode': '240',
      'countryCode': 'GQ'
   },
   {
      'country': 'Eritrea',
      'phoneCode': '291',
      'countryCode': 'ER'
   },
   {
      'country': 'Estonia',
      'phoneCode': '372',
      'countryCode': 'EE'
   },
   {
      'country': 'Ethiopia',
      'phoneCode': '251',
      'countryCode': 'ET'
   },
   {
      'country': 'Faroe Islands',
      'phoneCode': '298',
      'countryCode': 'FO'
   },
   {
      'country': 'Fiji',
      'phoneCode': '679',
      'countryCode': 'FJ'
   },
   {
      'country': 'Finland',
      'phoneCode': '358',
      'countryCode': 'FI'
   },
   {
      'country': 'France',
      'phoneCode': '33',
      'countryCode': 'FR'
   },
   {
      'country': 'French Guiana',
      'phoneCode': '594',
      'countryCode': 'GF'
   },
   {
      'country': 'French Polynesia',
      'phoneCode': '689',
      'countryCode': 'PF'
   },
   {
      'country': 'Gabon',
      'phoneCode': '241',
      'countryCode': 'GA'
   },
   {
      'country': 'Gambia',
      'phoneCode': '220',
      'countryCode': 'GM'
   },
   {
      'country': 'Georgia',
      'phoneCode': '995',
      'countryCode': 'GE'
   },
   {
      'country': 'Germany',
      'phoneCode': '49',
      'countryCode': 'DE'
   },
   {
      'country': 'Ghana',
      'phoneCode': '233',
      'countryCode': 'GH'
   },
   {
      'country': 'Gibraltar',
      'phoneCode': '350',
      'countryCode': 'GI'
   },
   {
      'country': 'Greece',
      'phoneCode': '30',
      'countryCode': 'GR'
   },
   {
      'country': 'Greenland',
      'phoneCode': '299',
      'countryCode': 'GL'
   },
   {
      'country': 'Grenada',
      'phoneCode': '1473',
      'countryCode': 'GD'
   },
   {
      'country': 'Guadeloupe',
      'phoneCode': '590',
      'countryCode': 'GP'
   },
   {
      'country': 'Guam',
      'phoneCode': '1671',
      'countryCode': 'GU'
   },
   {
      'country': 'Guatemala',
      'phoneCode': '502',
      'countryCode': 'GT'
   },
   {
      'country': 'Guinea',
      'phoneCode': '224',
      'countryCode': 'GN'
   },
   {
      'country': 'Guinea-Bissau',
      'phoneCode': '245',
      'countryCode': 'GW'
   },
   {
      'country': 'Guyana',
      'phoneCode': '595',
      'countryCode': 'GY'
   },
   {
      'country': 'Haiti',
      'phoneCode': '509',
      'countryCode': 'HT'
   },
   {
      'country': 'Honduras',
      'phoneCode': '504',
      'countryCode': 'HN'
   },
   {
      'country': 'Hungary',
      'phoneCode': '36',
      'countryCode': 'HU'
   },
   {
      'country': 'Iceland',
      'phoneCode': '354',
      'countryCode': 'IS'
   },
   {
      'country': 'India',
      'phoneCode': '91',
      'countryCode': 'IN'
   },
   {
      'country': 'Indonesia',
      'phoneCode': '62',
      'countryCode': 'ID'
   },
   {
      'country': 'Iraq',
      'phoneCode': '964',
      'countryCode': 'IQ'
   },
   {
      'country': 'Ireland',
      'phoneCode': '353',
      'countryCode': 'IE'
   },
   {
      'country': 'Israel',
      'phoneCode': '972',
      'countryCode': 'IL'
   },
   {
      'country': 'Italy',
      'phoneCode': '39',
      'countryCode': 'IT'
   },
   {
      'country': 'Jamaica',
      'phoneCode': '1876',
      'countryCode': 'JM'
   },
   {
      'country': 'Japan',
      'phoneCode': '81',
      'countryCode': 'JP'
   },
   {
      'country': 'Jordan',
      'phoneCode': '962',
      'countryCode': 'JO'
   },
   {
      'country': 'Kazakhstan',
      'phoneCode': '77',
      'countryCode': 'KZ'
   },
   {
      'country': 'Kenya',
      'phoneCode': '254',
      'countryCode': 'KE'
   },
   {
      'country': 'Kiribati',
      'phoneCode': '686',
      'countryCode': 'KI'
   },
   {
      'country': 'Kuwait',
      'phoneCode': '965',
      'countryCode': 'KW'
   },
   {
      'country': 'Kyrgyzstan',
      'phoneCode': '996',
      'countryCode': 'KG'
   },
   {
      'country': 'Latvia',
      'phoneCode': '371',
      'countryCode': 'LV'
   },
   {
      'country': 'Lebanon',
      'phoneCode': '961',
      'countryCode': 'LB'
   },
   {
      'country': 'Lesotho',
      'phoneCode': '266',
      'countryCode': 'LS'
   },
   {
      'country': 'Liberia',
      'phoneCode': '231',
      'countryCode': 'LR'
   },
   {
      'country': 'Liechtenstein',
      'phoneCode': '423',
      'countryCode': 'LI'
   },
   {
      'country': 'Lithuania',
      'phoneCode': '370',
      'countryCode': 'LT'
   },
   {
      'country': 'Luxembourg',
      'phoneCode': '352',
      'countryCode': 'LU'
   },
   {
      'country': 'Madagascar',
      'phoneCode': '261',
      'countryCode': 'MG'
   },
   {
      'country': 'Malawi',
      'phoneCode': '265',
      'countryCode': 'MW'
   },
   {
      'country': 'Malaysia',
      'phoneCode': '60',
      'countryCode': 'MY'
   },
   {
      'country': 'Maldives',
      'phoneCode': '960',
      'countryCode': 'MV'
   },
   {
      'country': 'Mali',
      'phoneCode': '223',
      'countryCode': 'ML'
   },
   {
      'country': 'Malta',
      'phoneCode': '356',
      'countryCode': 'MT'
   },
   {
      'country': 'Marshall Islands',
      'phoneCode': '692',
      'countryCode': 'MH'
   },
   {
      'country': 'Martinique',
      'phoneCode': '596',
      'countryCode': 'MQ'
   },
   {
      'country': 'Mauritania',
      'phoneCode': '222',
      'countryCode': 'MR'
   },
   {
      'country': 'Mauritius',
      'phoneCode': '230',
      'countryCode': 'MU'
   },
   {
      'country': 'Mayotte',
      'phoneCode': '262',
      'countryCode': 'YT'
   },
   {
      'country': 'Mexico',
      'phoneCode': '52',
      'countryCode': 'MX'
   },
   {
      'country': 'Monaco',
      'phoneCode': '377',
      'countryCode': 'MC'
   },
   {
      'country': 'Mongolia',
      'phoneCode': '976',
      'countryCode': 'MN'
   },
   {
      'country': 'Montenegro',
      'phoneCode': '382',
      'countryCode': 'ME'
   },
   {
      'country': 'Montserrat',
      'phoneCode': '1664',
      'countryCode': 'MS'
   },
   {
      'country': 'Morocco',
      'phoneCode': '212',
      'countryCode': 'MA'
   },
   {
      'country': 'Myanmar',
      'phoneCode': '95',
      'countryCode': 'MM'
   },
   {
      'country': 'Namibia',
      'phoneCode': '264',
      'countryCode': 'NA'
   },
   {
      'country': 'Nauru',
      'phoneCode': '674',
      'countryCode': 'NR'
   },
   {
      'country': 'Nepal',
      'phoneCode': '977',
      'countryCode': 'NP'
   },
   {
      'country': 'Netherlands',
      'phoneCode': '31',
      'countryCode': 'NL'
   },
   {
      'country': 'Netherlands Antilles',
      'phoneCode': '599',
      'countryCode': 'AN'
   },
   {
      'country': 'New Caledonia',
      'phoneCode': '687',
      'countryCode': 'NC'
   },
   {
      'country': 'New Zealand',
      'phoneCode': '64',
      'countryCode': 'NZ'
   },
   {
      'country': 'Nicaragua',
      'phoneCode': '505',
      'countryCode': 'NI'
   },
   {
      'country': 'Niger',
      'phoneCode': '227',
      'countryCode': 'NE'
   },
   {
      'country': 'Nigeria',
      'phoneCode': '234',
      'countryCode': 'NG'
   },
   {
      'country': 'Niue',
      'phoneCode': '683',
      'countryCode': 'NU'
   },
   {
      'country': 'Norfolk Island',
      'phoneCode': '672',
      'countryCode': 'NF'
   },
   {
      'country': 'Northern Mariana Islands',
      'phoneCode': '1670',
      'countryCode': 'MP'
   },
   {
      'country': 'Norway',
      'phoneCode': '47',
      'countryCode': 'NO'
   },
   {
      'country': 'Oman',
      'phoneCode': '968',
      'countryCode': 'OM'
   },
   {
      'country': 'Pakistan',
      'phoneCode': '92',
      'countryCode': 'PK'
   },
   {
      'country': 'Palau',
      'phoneCode': '680',
      'countryCode': 'PW'
   },
   {
      'country': 'Panama',
      'phoneCode': '507',
      'countryCode': 'PA'
   },
   {
      'country': 'Papua New Guinea',
      'phoneCode': '675',
      'countryCode': 'PG'
   },
   {
      'country': 'Paraguay',
      'phoneCode': '595',
      'countryCode': 'PY'
   },
   {
      'country': 'Peru',
      'phoneCode': '51',
      'countryCode': 'PE'
   },
   {
      'country': 'Philippines',
      'phoneCode': '63',
      'countryCode': 'PH'
   },
   {
      'country': 'Poland',
      'phoneCode': '48',
      'countryCode': 'PL'
   },
   {
      'country': 'Portugal',
      'phoneCode': '351',
      'countryCode': 'PT'
   },
   {
      'country': 'Puerto Rico',
      'phoneCode': '1939',
      'countryCode': 'PR'
   },
   {
      'country': 'Qatar',
      'phoneCode': '974',
      'countryCode': 'QA'
   },
   {
      'country': 'Romania',
      'phoneCode': '40',
      'countryCode': 'RO'
   },
   {
      'country': 'Rwanda',
      'phoneCode': '250',
      'countryCode': 'RW'
   },
   {
      'country': 'Samoa',
      'phoneCode': '685',
      'countryCode': 'WS'
   },
   {
      'country': 'San Marino',
      'phoneCode': '378',
      'countryCode': 'SM'
   },
   {
      'country': 'Saudi Arabia',
      'phoneCode': '966',
      'countryCode': 'SA'
   },
   {
      'country': 'Senegal',
      'phoneCode': '221',
      'countryCode': 'SN'
   },
   {
      'country': 'Serbia',
      'phoneCode': '381',
      'countryCode': 'RS'
   },
   {
      'country': 'Seychelles',
      'phoneCode': '248',
      'countryCode': 'SC'
   },
   {
      'country': 'Sierra Leone',
      'phoneCode': '232',
      'countryCode': 'SL'
   },
   {
      'country': 'Singapore',
      'phoneCode': '65',
      'countryCode': 'SG'
   },
   {
      'country': 'Slovakia',
      'phoneCode': '421',
      'countryCode': 'SK'
   },
   {
      'country': 'Slovenia',
      'phoneCode': '386',
      'countryCode': 'SI'
   },
   {
      'country': 'Solomon Islands',
      'phoneCode': '677',
      'countryCode': 'SB'
   },
   {
      'country': 'South Africa',
      'phoneCode': '27',
      'countryCode': 'ZA'
   },
   {
      'country': 'South Georgia and the South Sandwich Islands',
      'phoneCode': '500',
      'countryCode': 'GS'
   },
   {
      'country': 'Spain',
      'phoneCode': '34',
      'countryCode': 'ES'
   },
   {
      'country': 'Sri Lanka',
      'phoneCode': '94',
      'countryCode': 'LK'
   },
   {
      'country': 'Sudan',
      'phoneCode': '249',
      'countryCode': 'SD'
   },
   {
      'country': 'Suricountry',
      'phoneCode': '597',
      'countryCode': 'SR'
   },
   {
      'country': 'Swaziland',
      'phoneCode': '268',
      'countryCode': 'SZ'
   },
   {
      'country': 'Sweden',
      'phoneCode': '46',
      'countryCode': 'SE'
   },
   {
      'country': 'Switzerland',
      'phoneCode': '41',
      'countryCode': 'CH'
   },
   {
      'country': 'Tajikistan',
      'phoneCode': '992',
      'countryCode': 'TJ'
   },
   {
      'country': 'Thailand',
      'phoneCode': '66',
      'countryCode': 'TH'
   },
   {
      'country': 'Togo',
      'phoneCode': '228',
      'countryCode': 'TG'
   },
   {
      'country': 'Tokelau',
      'phoneCode': '690',
      'countryCode': 'TK'
   },
   {
      'country': 'Tonga',
      'phoneCode': '676',
      'countryCode': 'TO'
   },
   {
      'country': 'Trinidad and Tobago',
      'phoneCode': '1868',
      'countryCode': 'TT'
   },
   {
      'country': 'Tunisia',
      'phoneCode': '216',
      'countryCode': 'TN'
   },
   {
      'country': 'Turkey',
      'phoneCode': '90',
      'countryCode': 'TR'
   },
   {
      'country': 'Turkmenistan',
      'phoneCode': '993',
      'countryCode': 'TM'
   },
   {
      'country': 'Turks and Caicos Islands',
      'phoneCode': '1649',
      'countryCode': 'TC'
   },
   {
      'country': 'Tuvalu',
      'phoneCode': '688',
      'countryCode': 'TV'
   },
   {
      'country': 'Uganda',
      'phoneCode': '256',
      'countryCode': 'UG'
   },
   {
      'country': 'Ukraine',
      'phoneCode': '380',
      'countryCode': 'UA'
   },
   {
      'country': 'United Arab Emirates',
      'phoneCode': '971',
      'countryCode': 'AE'
   },
   {
      'country': 'United Kingdom',
      'phoneCode': '44',
      'countryCode': 'GB'
   },
   {
      'country': 'Uruguay',
      'phoneCode': '598',
      'countryCode': 'UY'
   },
   {
      'country': 'Uzbekistan',
      'phoneCode': '998',
      'countryCode': 'UZ'
   },
   {
      'country': 'Vanuatu',
      'phoneCode': '678',
      'countryCode': 'VU'
   },
   {
      'country': 'Wallis and Futuna',
      'phoneCode': '681',
      'countryCode': 'WF'
   },
   {
      'country': 'Yemen',
      'phoneCode': '967',
      'countryCode': 'YE'
   },
   {
      'country': 'Zambia',
      'phoneCode': '260',
      'countryCode': 'ZM'
   },
   {
      'country': 'Zimbabwe',
      'phoneCode': '263',
      'countryCode': 'ZW'
   },
   {
      'country': 'land Islands',
      'phoneCode': '',
      'countryCode': 'AX'
   },
   {
      'country': 'Bolivia, Plurinational State of',
      'phoneCode': '591',
      'countryCode': 'BO'
   },
   {
      'country': 'Brunei Darussalam',
      'phoneCode': '673',
      'countryCode': 'BN'
   },
   {
      'country': 'Cocos (Keeling) Islands',
      'phoneCode': '61',
      'countryCode': 'CC'
   },
   {
      'country': 'Congo, The Democratic Republic of the',
      'phoneCode': '243',
      'countryCode': 'CD'
   },
   {
      'country': 'Cote d\'Ivoire',
      'phoneCode': '225',
      'countryCode': 'CI'
   },
   {
      'country': 'Falkland Islands (Malvinas)',
      'phoneCode': '500',
      'countryCode': 'FK'
   },
   {
      'country': 'Guernsey',
      'phoneCode': '44',
      'countryCode': 'GG'
   },
   {
      'country': 'Holy See (Vatican City State)',
      'phoneCode': '379',
      'countryCode': 'VA'
   },
   {
      'country': 'Hong Kong',
      'phoneCode': '852',
      'countryCode': 'HK'
   },
   {
      'country': 'Iran, Islamic Republic of',
      'phoneCode': '98',
      'countryCode': 'IR'
   },
   {
      'country': 'Isle of Man',
      'phoneCode': '44',
      'countryCode': 'IM'
   },
   {
      'country': 'Jersey',
      'phoneCode': '44',
      'countryCode': 'JE'
   },
   {
      'country': 'Korea, Democratic People\'s Republic of',
      'phoneCode': '850',
      'countryCode': 'KP'
   },
   {
      'country': 'Korea, Republic of',
      'phoneCode': '82',
      'countryCode': 'KR'
   },
   {
      'country': 'Lao People\'s Democratic Republic',
      'phoneCode': '856',
      'countryCode': 'LA'
   },
   {
      'country': 'Libyan Arab Jamahiriya',
      'phoneCode': '218',
      'countryCode': 'LY'
   },
   {
      'country': 'Macao',
      'phoneCode': '853',
      'countryCode': 'MO'
   },
   {
      'country': 'Macedonia, The Former Yugoslav Republic of',
      'phoneCode': '389',
      'countryCode': 'MK'
   },
   {
      'country': 'Micronesia, Federated States of',
      'phoneCode': '691',
      'countryCode': 'FM'
   },
   {
      'country': 'Moldova, Republic of',
      'phoneCode': '373',
      'countryCode': 'MD'
   },
   {
      'country': 'Mozambique',
      'phoneCode': '258',
      'countryCode': 'MZ'
   },
   {
      'country': 'Palestinian Territory, Occupied',
      'phoneCode': '970',
      'countryCode': 'PS'
   },
   {
      'country': 'Pitcairn',
      'phoneCode': '872',
      'countryCode': 'PN'
   },
   {
      'country': 'Réunion',
      'phoneCode': '262',
      'countryCode': 'RE'
   },
   {
      'country': 'Russia',
      'phoneCode': '7',
      'countryCode': 'RU'
   },
   {
      'country': 'Saint Barthélemy',
      'phoneCode': '590',
      'countryCode': 'BL'
   },
   {
      'country': 'Saint Helena, Ascension and Tristan Da Cunha',
      'phoneCode': '290',
      'countryCode': 'SH'
   },
   {
      'country': 'Saint Kitts and Nevis',
      'phoneCode': '1869',
      'countryCode': 'KN'
   },
   {
      'country': 'Saint Lucia',
      'phoneCode': '1758',
      'countryCode': 'LC'
   },
   {
      'country': 'Saint Martin',
      'phoneCode': '590',
      'countryCode': 'MF'
   },
   {
      'country': 'Saint Pierre and Miquelon',
      'phoneCode': '508',
      'countryCode': 'PM'
   },
   {
      'country': 'Saint Vincent and the Grenadines',
      'phoneCode': '1784',
      'countryCode': 'VC'
   },
   {
      'country': 'Sao Tome and Principe',
      'phoneCode': '239',
      'countryCode': 'ST'
   },
   {
      'country': 'Somalia',
      'phoneCode': '252',
      'countryCode': 'SO'
   },
   {
      'country': 'Svalbard and Jan Mayen',
      'phoneCode': '47',
      'countryCode': 'SJ'
   },
   {
      'country': 'Syrian Arab Republic',
      'phoneCode': '963',
      'countryCode': 'SY'
   },
   {
      'country': 'Taiwan, Province of China',
      'phoneCode': '886',
      'countryCode': 'TW'
   },
   {
      'country': 'Tanzania, United Republic of',
      'phoneCode': '255',
      'countryCode': 'TZ'
   },
   {
      'country': 'Timor-Leste',
      'phoneCode': '670',
      'countryCode': 'TL'
   },
   {
      'country': 'Venezuela, Bolivarian Republic of',
      'phoneCode': '58',
      'countryCode': 'VE'
   },
   {
      'country': 'Viet Nam',
      'phoneCode': '84',
      'countryCode': 'VN'
   },
   {
      'country': 'Virgin Islands, British',
      'phoneCode': '1284',
      'countryCode': 'VG'
   },
   {
      'country': 'Virgin Islands, U.S.',
      'phoneCode': '1340',
      'countryCode': 'VI'
   }
];
}