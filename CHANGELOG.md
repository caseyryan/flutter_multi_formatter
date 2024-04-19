## [2.12.8]
- Merged https://github.com/caseyryan/flutter_multi_formatter/pull/155 /// Fix decimal separator issue for countries using "," as decimal separator #155
- https://github.com/caseyryan/flutter_multi_formatter/pull/153 /// Add Won sign
- https://github.com/caseyryan/flutter_multi_formatter/pull/152 /// New mask for Germany
## [2.12.4]
- Added one more UZ_CARD format and HUMO according to this thread https://github.com/caseyryan/flutter_multi_formatter/issues/150
## [2.12.3]
- Added toStringAsSmartRound() to double extension
- Re-Fixed a problem with incorrect rounding if mantissa == 0
## [2.12.2]
- Removed BTC from the list of fiat currencies
## [2.12.1]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/136 Error Range start 5 is out of text of length 1 #136

## [2.12.0]
- Updated SKD restrictions
- formatAsCardNumber now also tries to format invalid cards
- Added `toPhoneNumber()`, `toCardNumber()`, `isValidCardNumber()` string extensions
## [2.11.16]
- Added DoNothing clause
## [2.11.15]
- Added PhoneCodes.removeCountryCode method which simply remove a country code from a phone
- PhoneCodes.getCountryDataByPhone now accepts phones with a leading plus
## [2.11.14]
- Fixed Luhn algorithm
## [2.11.12]
- Updated README
- Added this https://github.com/caseyryan/flutter_multi_formatter/issues/137
## [2.11.11]
- Merged https://github.com/caseyryan/flutter_multi_formatter/pull/142
## [2.11.10]
- Completely changed the logic of Unfocuser widget since the previous one 
doesn't work anymore
## [2.11.9]
Fixed Czech phone mask
https://github.com/caseyryan/flutter_multi_formatter/issues/141
## [2.11.8]
Merged https://github.com/caseyryan/flutter_multi_formatter/pull/140 
adding isForce parameter to getAllCountryCodes
## [2.11.7]
- Fixed missing Luhn algo check in isCardNumberValid function 
## [2.11.6]
Potential fix https://github.com/caseyryan/flutter_multi_formatter/issues/114
## [2.11.5]
Added Luhn algorithm to validate card numbers
## [2.11.4]
Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/131
Added new card system https://github.com/caseyryan/flutter_multi_formatter/issues/109
- Fixed a bug with incorrect decimal point detection when mantissa length is 0
## [2.11.2]
- Merged this pull request https://github.com/caseyryan/flutter_multi_formatter/pull/132
## [2.11.1]
- Correct mask for Congo number https://github.com/caseyryan/flutter_multi_formatter/pull/127
## [2.11.0]
- CountryDropdown now only selects initialCountryData instead of phone code
because there are cases when different countries share the same phone code 
and we still need to tell them apart
## [2.10.9]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/123
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/116
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/122 by adding triggerOnCountrySelectedInitially param to CountryDropdown
## [2.10.5]
- CountryDropdown can now be filtered. If you need it to show only a 
predefined list of countries. Just pass "filter" parameter like this 
```child: CountryDropdown(
        printCountryName: true,
        initialPhoneCode: '7',
        filter: PhoneCodes.findCountryDatasByCountryCodes(
        countryIsoCodes: [
            'RU',
            'BR',
            'DE',
        ],
        ),
        onCountrySelected: (PhoneCountryData countryData) {
        setState(() {
            _initialCountryData = countryData;
        });
        },
    ) 
```
## [2.10.4]
- Unfocuser now has isEnabled parameter so it can be easily disabled when it's 
not necessage e.g. on the web
## [2.10.3]
- CountryDropdown now does not have initialCountryCode parameter but uses initialPhoneCode instead, because some countries might have a few phone codes and we need to determin which one of them should be used
## [2.10.2]
- Fixed a problem with incorrect card system detection
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/113
## [2.10.1]
- A few fixes to PinyinUtils
## [2.10.0]
- Merged https://github.com/caseyryan/flutter_multi_formatter/pull/112
## [2.9.14]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/111
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/110
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/108
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/107
## [2.9.11]
- Added promptTonesForPinyin() static function to PinyinUtils. 
It can give you a list of its vowels with all possible tones
## [2.9.10]
- Added di pinyin to HanziUtils
## [2.9.9]
- Cleared some prints
## [2.9.8]
- Fixed a bug when pinyin formatter removed all characters that didn't match valid syllables
## [2.9.7]
- Fixed a period at the end if mantissa length is 0 https://github.com/caseyryan/flutter_multi_formatter/issues/106
## [2.9.6]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/105
## [2.9.5]
- Added hsk levels to HanziUtils
## [2.9.4]
- Fixed a problem when pinyin splitter didn't work if there's only one syllable provided
## [2.9.3]
- More fixes to pinyin utils
## [2.9.2]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/104
## [2.9.1]
- Fixed crashes in PinyinUtils if the provided string is empty
## [2.9.0]
- Added more pinyin utils + HanziUtils
- Added to utility methods for currencies isCryptoCurrency(String currencyId) and isFiatCurrency(String currencyId)
## [2.8.8]
- One more minor fix for PinyinUtils
## [2.8.7]
- Fixed Pakistan number mask https://github.com/caseyryan/flutter_multi_formatter/issues/103
## [2.8.6]
- Fixed PinyinUtils.simplifyPinyin() it could brake on pinyins 
with the same letters coming in a row like bùdéérzhī 
## [2.8.5]
- Cleaned up some prints
## [2.8.4]
- Advanced Pinyin splitter. It does not depend on regular expressions anymore
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/100
instead it uses a list of real syllables thus works much better
it can also detect a syllable tone
## [2.8.2]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/97
## [2.8.1]
- Added a utility method PinyinUtils.simplifyPinyin();
## [2.8.0]
- Introducing PinyinFormatter for Chinese language 
## [2.7.6]
- PhoneCountryData now has toMap() method, that converts it into a hash map. 
This might be useful e.g. for json encoders/revivers 
## [2.7.5]
- Fixed a critical bug with CreditCardExpirationInputFormatter https://github.com/caseyryan/flutter_multi_formatter/issues/96
## [2.7.4]
- Removed "borderRadius" parameter from CountryDropdown to make it compatible with some older Flutter versions
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/92
## [2.7.2]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/93
## [2.7.1]
- Added "printCountryName" option to CountryDropdown
## [2.7.0]
- Added a possibility to add a pre-defined country code for phone formatter
See example to know how to use it. And added a new dropdown type CountryDropdown
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/91
- https://github.com/caseyryan/flutter_multi_formatter/issues/89
## [2.6.2]
- Merged https://github.com/caseyryan/flutter_multi_formatter/pull/88
## [2.6.1]
- Fixed currency input formatter empty value error https://github.com/caseyryan/flutter_multi_formatter/issues/87
## [2.6.0]
- Made it possible to enter a leading plus https://github.com/caseyryan/flutter_multi_formatter/issues/85
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/80
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/86
- Deprecated MoneyInputFormatter in favor of a more reliable new CurrencyInputFormatter
## [2.5.8]
- Added a MasterCard 52* credit card support
## [2.5.7]
- Added a support for Diners Club cards starting with 30
## [2.5.6]
- Mastercard 222* support
## [2.5.5]
- Fixed Iraq phone number https://github.com/caseyryan/flutter_multi_formatter/pull/82
## [2.5.4]
- Added more card systems support
- CreditCardCvvInputFormatter now accepts ```isAmericaExpress``` value
 if it's true, it will accept 4 digits, else 3 https://github.com/caseyryan/flutter_multi_formatter/issues/76
- Merged flutter lint changes https://github.com/caseyryan/flutter_multi_formatter/pull/81
- Rewritten MaskedInputFormatter. Now it's more robust and correct https://github.com/caseyryan/flutter_multi_formatter/issues/73
## [2.5.1]
- New PosInputFormatter. Thanks to [SimoneBressan](https://github.com/SimoneBressan) for this contribution 
- Fixed the issue with CreditCardExpirationDateFormatter https://github.com/caseyryan/flutter_multi_formatter/issues/70
## [2.4.4]
- https://github.com/caseyryan/flutter_multi_formatter/issues/68 fixed a typo in README section
- Added alternative mask for Australean phone numbers
- Added a correct phone mask for United Arab Emirates
## [2.4.1]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/62
## [2.4.0]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/61
- Fixed orphan leading period formatting in strings like 
$.5. Now they are formatted correctly to $0.5, not $500.00
## [2.3.8]
- One more small fix
## [2.3.7]
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/59
- Fixed https://github.com/caseyryan/flutter_multi_formatter/issues/60
## [2.3.5]
- Added correct Hungarian phone masks: +00 0 000 0000 for Budapest and +00 00 000 0000 for all other numbers. Hungarian phones now also support alternative country code +06 as well as +36
- Changed the logic of MaskedInputFormatter. Now it can format the value correctly 
on erasing as well as on entering. 
BREAKING CHANGES: MaskedInputFormatter#applyMask() now returns FormattedValue object
instead of String. To get a string value out of it simply call its .toString() method
## [2.3.3]
- CreditCardNumberInputFormatter now works in two directions. When you enter the number and when you erase it
## [2.3.2]
- Fixed a bug with masked value in a Russian phone format
## [2.3.1]
- Updated formatting
## [2.3.0]
- Added a bitcoin wallet validator which supports regular BTC addresses as well as 
SegWit (Bech32)
## [2.2.1]
- Improved documentation
## [2.2.0]
- BUG FIXES in MoneyInputFormatter
Fixed a bug with ThousandSeparator.None described here 
https://github.com/caseyryan/flutter_multi_formatter/issues/50
Fixed a bug with wrong selection after several spaces have been 
added as thousand separators. The caret might have gone after the mantissa 
- Fixed a bug that allowed to enter somthing like $02,500.00 where leading zero 
must not have beed allowed
## [2.1.4]
- More search friendly description
## [2.1.3]
- Fixed Chinese phone mask
## [2.1.2]
- Changed Kazakhstan phone code to 7 (which is correct)
- Fixed MaskedInputFormatter applyMask (merged this pull request https://github.com/caseyryan/flutter_multi_formatter/pull/46)
## [2.1.0]
- Fixed a bug with adding custom phone masks mentioned in this issue https://github.com/caseyryan/flutter_multi_formatter/issues/40
- PhoneCodes class is now public and can be accessed to get different data
- Removed deprecated RestrictingInputFormatters in favor of a Lutter's build in - FilteringTextInputFormatter
- Fix a bug with any character input entioned here https://github.com/caseyryan/flutter_multi_formatter/issues/38
## [2.0.3]
Added a support for Russian national payment system "МИР" (it's read as MEER, and literally means "The World" but it also means "Peace", this is just for those who are curious :) )
the number of the card is formatted just like Visa or Mastercard but 
it has a different system code
## [2.0.2]
- Updated phone masks for France and oversees territories
## [2.0.1]
- Fixed a bug when null sefety version threw an error trying to cast
bool Function(Map<String, dynamic>)->bool Function(Map<String, dynamic>?)
## [2.0.0]
- Starting from this version the package is Null-safe. This means it requires 
a minimum version of Flutter 2.0.0 and Dart 2.12.0
- Fixed a bug with space as thousands separators
## [1.3.6]
Unfocuser now has a parameter called minScrollDistance
it allows you to not trigger Unfocuser on scroll. Any value greater 
than this will be considered as scrolling and the Unfocuser will not trigger. If you want it to always unfocus current text input, set this value to 0.0, or null.
## [1.3.5]
- Fixed a bug which caused erasing 2 more zeroes when erasing just one
## [1.3.4]
- Fixed a bug in isPhoneValid method which didn't allow to check the phone correctly
## [1.3.3]
- Added support for alternative phone masks. As some countries might 
have different phone masks there is a need for supporting this feature. 
Now some country datas e.g. Brazil or Estonia have several phone masks.
You don't need to set up something for it, this is totally automatic.
Everything is used just like before and the relevant mask is detected and 
applied internally
- Fixed a bug when a phone was not formatted on erasing
- Added support for custom phone masks. If, for some reason a phone mask 
is not present in current database or you want to change mask format for some
country you can easeily do so by using static methods PhoneInputFormatter.addAlternativePhoneMasks() or PhoneInputFormatter.replacePhoneMask() 
somewhere in your app, e.g. main() method so that the changes were available
right away

## [1.3.0]
- Added RestrictingInputFormatter that allows to restrict or to allow 
some characters in an input field
## [1.2.3]
- Added a possibility to limit text length while formatting
## [1.2.2]
- Fixed a bug with inability to enter a text when in was first empty
## [1.2.1]
- Flutter version lowered to 1.22.3
## [1.2.0]
- Fixed an issue with double zeroes when applying more period after erasing
- Fixed a bug with format when using periods as thousand separators. Now 
the automatic formatting does not depend on whether you select commas or periods 
- Now the text is formatting not only while typing but also when erasing
- The plugin now requires a minumum version of flutter 1.22.4 because 
of a critical but with a base TextInputFormatter in previous releases and 
dart sdk 2.10.2 or newer. Sorry for this but it was really necessary
- Added more money symbols. Now there are stored in string constants inside 
MoneySymbols class. Just use MoneySymbols.BITCOIN_SIGN if you need Ƀ for example
- Fixed some phone masks for different countries

## [1.1.8]
- Apllied some formatting
## [1.1.7]

- Phone maskes now are not restricted by length. The number is masked as before
and a country is detected but now you can enter any number of digits after the 
mask if filled. This is necessary for some countries that have a 
variable number of digits in their phone numbers e.g. Estonia

## [1.1.6]

- Added a possibility to use a period as a thousand separator

## [1.1.5]

- Added support for 6 card systems for now. If the card number is detected 
as one of the supported systems, e.g. Mastercard, it will be formatted automatically
and the callback with CardSystemData argument will be called
- CreditCardHolderNameFormatter was completely removed. There's no need for this formatter
- CreditCardNumberFormatter was replaced with CreditCardNumberInputFormatter which is more flexible
- CvvCodeFormatter was renamed to CreditCardCvcInputFormatter
- CreditCardExpirationDateFormatter was renamed to CreditCardExpirationDateFormatter


## [1.1.1]

- Fixed a bug in masked input formatter which allowed to enter an odd symbol 
in some circumstances

## [1.1.0]

- Added MoneyInputFormatter

## [1.0.3]

- Initial pub release. Includes a list of formatters:

PhoneInputFormatter
MaskedInputFormatter
CreditCardNumberFormatter
CvvCodeFormatter
CreditCardExpirationDateFormatter
CreditCardHolderNameFormatter