# flutter_multi_formatter

<a href="https://pub.dev/packages/flutter_multi_formatter"><img src="https://img.shields.io/pub/v/flutter_multi_formatter?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) <a href="https://github.com/Solido/awesome-flutter">
<img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>

---
If you want to support my development you can donate some `ETH / USDT`
**0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1**

<img src="https://github.com/caseyryan/reflect_buddy/blob/master/trust.jpg?raw=true" width="220"/>

[Donate some Ethereum or USDT](https://link.trustwallet.com/send?address=0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1&asset=c60)

---

**You might also like my other packages**

**[lite_state](https://pub.dev/packages/lite_state)** 
(Very simple and easy to use state machine for Flutter)


<a href="https://pub.dev/packages/lite_state"><img src="https://img.shields.io/pub/v/lite_state?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) <a href="https://github.com/Solido/awesome-flutter">
<img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>

**[flutter_instagram_storyboard](https://pub.dev/packages/flutter_instagram_storyboard)**
(A UI for setting up stories like in Instagram)


<a href="https://pub.dev/packages/flutter_instagram_storyboard"><img src="https://img.shields.io/pub/v/flutter_instagram_storyboard?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) <a href="https://github.com/Solido/awesome-flutter"></a>



## Formatters Included

1. `Phone Formatter`
2. `Credit / Debit Card Formatter`
3. `Money Formatter`
4. `Masked Formatter`
5. `Pinyin syllable separating formatter`

## Special utilities 

1. `Bitcoin (BTC) wallet validator;`
2. `Digit extractor (allows to extract all digits out of a string)`
3. `Phone number validator (the check is based on country phone codes and masks so it's a more serious and reliable validation than a simple regular expression)`
4. `"Is digit" checker (Simply checks if an input string value a digit or not)`
5. `Currency string formatter (allows to convert a number to a currency string representation e.g. this 10000 to this 10,000.00$)`
6. `Unfocuser (a widget that is used to unfocus any text fields without any boilerplate code. Extremely simple to use)`
7. PinyinUtils class that contains a few useful methods to work with chinese 
pinyin
    - PinyinUtils.clearPunctuation : removes all punctuations from a string, including special chinese punctuation
    - PinyinUtils.containsTone: returns true if a string contains some tone. False otherwise
    - PinyinUtils.getPinyinTones returns a list of int's with all syllable tones in a sentence
    - PinyinUtils.getPinyinTone the same as PinyinUtils.getPinyinTones but for a single syllable. Returns its tone. 5 means neutral tone
    - PinyinUtils.splitToSyllables<T>: a generic function that can accept String or SyllableData as a generic constraint and return a list of objects of this type. SyllableData is more advanced then just a string. Use it if you need to know if a string is a valid pinyin as well as its tone


### Formatting a phone

<img src="https://github.com/caseyryan/images/blob/master/multi_formatter/phone_format.gif?raw=true" width="240"/>


```dart
PhoneInputFormatter.replacePhoneMask(
    countryCode: 'RU',
    newMask: '+0 (000) 000 00 00',
);
PhoneInputFormatter.addAlternativePhoneMasks(
    countryCode: 'BR',
    alternativeMasks: [
    '+00 (00) 0000-0000',
    '+(00) 00000',
    '+00 (00) 00-0000',
    ],
);
/// There is also a possibility to enter endless phones 
/// by setting allowEndlessPhone to true 
/// this means that you can enter a phone number of any length
/// its part that matches a mask will be formatted 
/// and the rest will be entered unformatted
/// is will allow you to support any phones (even those that are not supported by the formatter yet)
PhoneInputFormatter(
    onCountrySelected: _onCountrySelected,
    allowEndlessPhone: true,
)
```
## Using a pre-defined country code 

<img src="https://github.com/caseyryan/images/blob/master/multi_formatter/phone_country_dropdown.gif?raw=true" width="240"/>

```dart
PhoneCountryData? _initialCountryData;
...

Row(
  children: [
    Expanded(
      flex: 3,
      child: CountryDropdown(
        printCountryName: true,
        initialPhoneCode: '7',
        onCountrySelected: (PhoneCountryData countryData) {
          setState(() {
            _initialCountryData = countryData;
          });
        },
      ),
    ),
    SizedBox(width: 10.0),
    Expanded(
      flex: 5,
      child: TextFormField(
        key: ValueKey(_initialCountryData ?? 'country'),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: _initialCountryData?.phoneMaskWithoutCountryCode,
          hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
          errorStyle: TextStyle(
            color: Colors.red,
          ),
        ),
        keyboardType: TextInputType.phone,
        inputFormatters: [
          PhoneInputFormatter(
            allowEndlessPhone: false,
            defaultCountryCode: _initialCountryData?.countryCode,
          )
        ],
      ),
    )
  ],
)
```

You can also filter the list of countries if you need 

```dart
CountryDropdown(
    printCountryName: true,
    initialPhoneCode: '7',
    filter: PhoneCodes.findCountryDatasByCountryCodes(
    countryIsoCodes: [
        'RU',
        'BR',
        'DE',
    ],
)
```


### Formatting a credit / debit card

<img src="https://github.com/caseyryan/images/blob/master/multi_formatter/card_format.gif?raw=true" width="240"/>

### Formatting currencies

<img src="https://github.com/caseyryan/images/blob/master/multi_formatter/money_format.gif?raw=true" width="240"/>


## Using:
```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
```


## A list of formatters included

```dart
/// for phone numbers with a fully automated detection
PhoneInputFormatter
PinyinFormatter

/// for anything that can be masked
MaskedInputFormatter

/// for credit / debit cards
CreditCardNumberInputFormatter
CreditCardCvcInputFormatter
CreditCardExpirationDateFormatter

/// for currencies
CurrencyInputFormatter
PosInputFormatter
```

## Utility methods and widgets

Validates Bitcoin wallets (also supports bech32)

You can use these example wallets to test the validator

**P2PKH addresses start  with the number 1**
`Example: 1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2`

**P2SH addresses start with the number 3**
`Example: 3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy`

**Bech32 addresses also known as "bc1 addresses" start with bc1**
`Example: bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq`

```dart
/// a simple check if its a BTC wallet or not, regardless of its type
bool isBitcoinWalletValid(String value);

/// a bit more complicated check which can return the type of 
/// BTC wallet and return SegWit (Bech32), Regular, or None if 
/// the string is not a BTC address
BitcoinWalletType getBitcoinWalletType(String value);

/// Detailed check, for those who need to get more details 
/// of the wallet. Returns the address type, the network, and 
/// the wallet type along with its address. 
/// It always returns BitcoinWalletDetails object. To check if it's
/// valid or not use bitcoinWalletDetails.isValid getter
/// IMPORTANT The BitcoinWalletDetails class overrides an 
/// equality operators so two BitcoinWalletDetails objects can be 
/// compared simply like this bwd1 == bwd2
BitcoinWalletDetails getBitcoinWalletDetails(String? value);

```
<img src="https://github.com/caseyryan/images/blob/master/multi_formatter/bitcoin.gif?raw=true" width="240"/>


Gets all numbers out of a string and joins them into a new string
e.g. a string like fGgfjh456bb78 will be converted into this: 45678

```dart 
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

String toNumericString(String text);
```

returns 'true' if the checked character is a digit

```dart 
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

bool isDigit(String character);
```

toCurrencyString() is used by the CurrencyInputFormatter internally 
but you can also use it directly
```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

String toCurrencyString(String value, {
    int mantissaLength = 2,
    /// in case you need a period as a thousand separator
    /// simply change ThousandSeparator.Comma to ThousandSeparator.Period
    /// and you will get 1.000.000,00 instead of 1,000,000.00
    ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
    ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
    String leadingSymbol = '',
    String trailingSymbol = '',
    bool useSymbolPadding = false
});

print(toCurrencyString('123456', leadingSymbol: CurrencySymbols.DOLLAR_SIGN)); // $123,456.00

/// the values can also be shortened to thousands, millions, billions... 
/// in this case a 1000 will be displayed as 1K, and 1250000 will turn to this 1.25M
var result = toCurrencyString(
    '125000', 
    leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
    shorteningPolicy: ShorteningPolicy.RoundToThousands
); // $125K

result = toCurrencyString(
    '1250000', 
    leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
    shorteningPolicy: ShorteningPolicy.RoundToMillions
); // 1.25M

```
There's also an "extension" version of this function which can be used on 
double, int and String.

```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

var someNumericValue = 123456;
print(someNumericValue.toCurrencyString(leadingSymbol: CurrencySymbols.DOLLAR_SIGN)); // $123,456.00

var someNumericStringValue = '123456';
print(someNumericStringValue.toCurrencyString(trailingSymbol: CurrencySymbols.EURO_SIGN)); // 123,456.00€
```  

```dart 
Unfocuser()
```
Unfocuser allows you to unfocus any text input and hide the onscreen keyboard 
when you tap outside of a text input. Use it like this:

```dart 
@override
Widget build(BuildContext context) {
return Unfocuser(
    child: Scaffold(
    body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
            key: _formKey,
            child: Column(
            children: <Widget>[
                TextFormField(
                keyboardType: TextInputType.phone,
                inputFormatters: [
                    PhoneInputFormatter()
                ],
                ),
            ],
            ),
        ),
        ),
    ),
    ),
);
}
```


### More detailed description

```dart
PhoneInputFormatter()
```

Automatically detects the country the phone number belongs to and formats the number according 
to its mask.
You don't have to care about keeping track of the list of countries or anything else.
The whole process is completely automated.
You simply add this formatter to the list of formatters like this:

```dart
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        PhoneInputFormatter()
    ],
),
```

You can also get a country data for the selected phone number by simply passing a callback function to your 
formatter.

```dart
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        PhoneInputFormatter(onCountrySelected:  (PhoneCountryData countryData) {
            print(countryData.country);
        });
    ],
),
```

```dart
CreditCardNumberInputFormatter()
```
CreditCardNumberInputFormatter automatically detects a type of a card based on a predefined 
list of card system and formats the number accordingly. 
This detection is pretty rough and may not work with many card system. 
All supported systems are available as string constants in 

```dart
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
}
```
Anyway, if the number is not supported it will just be returned as it is and your input will not 
break because of that


```dart
TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        CreditCardNumberInputFormatter(onCardSystemSelected:  (CardSystemData cardSystemData) {
            print(cardSystemData.system);
        });
    ],
),

/// there's also a method to format a number as a card number
/// the method is located in a credit_card_number_input_formatter.dart file
String formatAsCardNumber(
String cardNumber, {
    bool useSeparators = true,
});

/// and a method to check is a card is valid
bool isCardNumberValid(required String cardNumber,
  bool checkLength = false,
  bool useLuhnAlgo = true,
});
/// but it will return true only if the card system is supported, 
/// so you should not really rely on that

```


## Masked formatter

```dart
MaskedInputFormatter()
```
This formatter allows you to easily format a text by a mask
This formatter processes current text selection very carefully so that input does not 
feel unnatural
Use it like any other formatters

```dart
/// # matches any character and 0 matches digits
/// so, in order to format a string like this GHJ45GHJHN to GHJ-45-GHJHN
/// use a mask like this
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        MaskedInputFormatter('###-00-#####')
    ],
),
```
But in case you want # (hash symbol) to match only some particular values, you can pass 
a regular expression to [anyCharMatcher] parameter

```dart
/// in this scenario, the # symbol will only match uppercase latin letters
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        MaskedInputFormatter('###-00-#####', anyCharMatcher: RegExp(r'[A-Z]'))
    ],
),
```


## Money Input formatter

```dart
CurrencyInputFormatter()
```

```dart
TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        CurrencyInputFormatter(
            leadingSymbol: CurrencySymbols.DOLLAR_SIGN
        )
    ],
),
...

TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        CurrencyInputFormatter
            trailingSymbol: CurrencySymbols.EURO_SIGN,
            useSymbolPadding: true,
            mantissaLength: 3 // the length of the fractional side
        )
    ],
),

```

## Point of Sale input formatter
```dart
PosInputFormatter
```
Allows you to enter numbers like you would normally do 
on a sales terminal 
```dart
TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        PosInputFormatter(),
    ],
),
```


## Chinese Pinyin separating

<img src="https://github.com/caseyryan/images/blob/master/multi_formatter/pinyin.gif?raw=true" width="240"/>

```dart
PinyinFormatter
```
Allows to split a phrase into pinyin syllables
e.g. wohenhaonine?
will turn into 
wo'hen'hao'ni'ne? 
It works irregarding tones, so you can enter text with plain english
characters and it will still work

```dart
TextFormField(
    inputFormatters: [
        PinyinFormatter(),
    ],
),
```

Or you can use some utility methods like 
```dart 
final value = PinyinUtils.splitToSyllablesBySeparator(
    'wǒhěngāoxìngrènshinǐ',
);
print(value); /// wǒ'hěn'gāo'xìng'rèn'shi'nǐ
```


For more details see [example](https://github.com/caseyryan/flutter_multi_formatter/tree/master/example) project. And feel free to open an issue if you find any bugs of errors
