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